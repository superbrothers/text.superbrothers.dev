---
title: "Kubernetes 1.18: clientgofix を使って client-go の新しいインタフェイスに移行する"
date: 2020-04-06T22:03:04+09:00
draft: false
tags: ["kubernetes"]
images: ["/ogp/200406-trying-to-use-clientgofix.png"]
---

Kubernetes 1.18 で k8s.io/client-go でいくつかの変更が入りました。詳しくは次のとおりです。

> 生成されたclientset、dynamic/metadata/scaleクライアントのメソッドは第一引数にcontext.Contextをとるようになりました。また、Create、Update、Patchメソッドはそれぞれ引数にCreateOptions、UpdateOptions、PatchOptionsをとります。Delete及びDeleteCollectionメソッドはDeleteOptionsを参照ではなく値として受け付けるようになりました。  
> 以前のインタフェースで生成されたclientsetは、新しいAPIへの逐次的な移行を可能にするために、新しい「非推奨」パッケージで追加されました。非推奨パッケージは1.21のリリース時に削除されます。この移行をサポートするためのツールは http://sigs.k8s.io/clientgofix で提供されています

- [Kubernetes 1\.18: SIG\-API Machineryの変更内容 \- Qiita](https://qiita.com/Ladicle/items/bbe2a62aba85d083283d)

上にあるとおり、新しいインタフェイスの API に移行するための `clientgofix` という便利ツールが用意されています。ここでは私が趣味で開発している `kubectl open-svc` プラグインで使ってみます。

最初に `clientgofix` の README にあるとおりの手順でインストールします。

```
$ git clone https://github.com/kubernetes-sigs/clientgofix.git
$ cd clientgofix
$ make install
Expected: go version go1.13.*, go1.14.*, or devel
Found:    go version go1.14 darwin/amd64
make: *** [check_go_version] Error 1
```

Go のバージョンチェックに失敗しています。どこかしらかの Homebrew の更新で Go 1.14 に更新されてしまっているかつバージョンが `1.14` となっており、バリデートに失敗しているようです。ここでは [asdf-vm](https://asdf-vm.com/) を使って Go 1.13.9 をインストールします。`asdf` べんりです。

```
$ asdf install golang 1.13.9
$ asdf global golang 1.13.9
$ go version
go version go1.13.9 darwin/amd64
```

改めてインストールします。

```
$ make install
$ clientgofix -version
clientgofix version v0.3.0-2-g96f27576f2
```

インストールできました。では次に [superbrothers/kubectl-open-svc-plugin](https://github.com/superbrothers/kubectl-open-svc-plugin) リポジトリで `clientgofix` を使ってます。

その前にまず依存ライブラリのバージョンを上げてみてビルドできるかどうか試してみます。

```
$ git clone https://github.com/superbrothers/kubectl-open-svc-plugin.git && cd kubectl-open-svc-plugin
$ git show -q
commit f6f1f2ed54dbb9cea8f72ff47ac11a9338d1d1b8 (HEAD -> master, tag: v2.3.0, origin/master, origin/HEAD)
Author: Kazuki Suda <230185+superbrothers@users.noreply.github.com>
Date:   Thu Dec 26 18:00:01 2019 +0900

    Add license file into archive files (#31)
```

ここでは次のように `go.mod` を変更します。

```diff
diff --git a/go.mod b/go.mod
index 1d3a1e8..68b6ace 100644
--- a/go.mod
+++ b/go.mod
@@ -1,14 +1,14 @@
 module github.com/superbrothers/kubectl-open-svc-plugin

-go 1.12
+go 1.13

 require (
        github.com/pkg/browser v0.0.0-20180916011732-0a3d74bf9ce4
        github.com/spf13/cobra v0.0.5
        github.com/spf13/pflag v1.0.5
        k8s.io/apimachinery v0.17.1-beta.0
-       k8s.io/cli-runtime v0.17.0
-       k8s.io/client-go v0.17.0
+       k8s.io/cli-runtime v0.18.0
+       k8s.io/client-go v0.18.0
        k8s.io/klog v1.0.0
-       k8s.io/kubectl v0.17.0
+       k8s.io/kubectl v0.18.0
 )
```

そのままビルドしてみます。

```
$ make build
GO111MODULE=on go build -o kubectl-open_svc cmd/kubectl-open_svc.go
go: downloading sigs.k8s.io/structured-merge-diff v0.0.0-20190525122527-15d366b2352e
# github.com/superbrothers/kubectl-open-svc-plugin/pkg/cmd
pkg/cmd/open-svc.go:161:57: not enough arguments in call to client.CoreV1().Services(namespace).Get
        have (string, "k8s.io/apimachinery/pkg/apis/meta/v1".GetOptions)
        want (context.Context, string, "k8s.io/apimachinery/pkg/apis/meta/v1".GetOptions)
make: *** [build] Error 2
```

`client-go` の `clientset` でのメソッドの第一引数に `context.Context` を取るようになった変更で失敗しています。では `clientgofix` を使ってみます。

```
$ clientgofix ./...
loaded 2 packages in 3.603998516s
/Users/ksuda/dev/kubectl-open-svc-plugin/pkg/cmd/open-svc.go
  161: Get: added context import
  161: Get: inserted context.Context as arg 0
$ make build
GO111MODULE=on go build -o kubectl-open_svc cmd/kubectl-open_svc.go
```

正しくビルドできました。変更された内容は次のとおりです。

```diff
diff --git a/pkg/cmd/open-svc.go b/pkg/cmd/open-svc.go
index 1023e9a..91e7a93 100644
--- a/pkg/cmd/open-svc.go
+++ b/pkg/cmd/open-svc.go
@@ -1,6 +1,7 @@
 package cmd

 import (
+       "context"
        "flag"
        "fmt"
        "os"
@@ -158,7 +159,7 @@ func (o *OpenServiceOptions) Run() error {
                return err
        }

-       service, err := client.CoreV1().Services(namespace).Get(serviceName, metav1.GetOptions{})
+       service, err := client.CoreV1().Services(namespace).Get(context.TODO(), serviceName, metav1.GetOptions{})
        if err != nil {
                return fmt.Errorf("Failed to get service/%s in namespace/%s: %v\n", serviceName, namespace, err)
        } 
```

この kubectl プラグインは小さいので人間が修正したほうが早いのですが、それなりの Kubernetes コントローラであれば `clientgofix` を使うことで間違えることなく移行できてべんりそうです。

また、kubectl プラグインでは、多くの場合 [spf13/cobra](https://github.com/spf13/cobra) を使っていると思いますが、[context.Context のサポート](https://github.com/spf13/cobra/pull/893)が先日入ったので、合わせて対応するとよさそうです。
