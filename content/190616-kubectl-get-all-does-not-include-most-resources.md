---
title: "kubectl get all は全リソースの情報を表示しない"
date: 2019-06-16T04:41:03Z
draft: false
---

## TL;DR

- `kubectl get all` は、v1.14.3 時点で次のリソースの情報のみを表示し、全リソースが対象ではない
    - pods.v1
    - replicationcontrollers.v1
    - services.v1
    - cronjobs.batch
    - daemonsets.apps
    - deployments.apps
    - horizontalpodautoscalers.autoscaling
    - jobs.batch
    - replicasets.apps
    - statefulsets.apps
- 本当に全リソースの情報を表示するには、次のワンライナが利用できる  
    ```
    kubectl get "$(kubectl api-resources --namespaced=true --verbs=list -o name | tr "\n" "," | sed -e 's/,$//')"
    ```
- ワンライナを kubectl プラグインとしておくと便利

## はじめに

`kubectl get all` は、その見た目からあたかも利用できる全リソースの情報を出力するように見えますが、DaemonSet も Ingress も含まれていません。真に全リソースの情報を出力するには、簡単なワンライナが利用できます。また、それを kubectl プラグインとして使えるようにしておくと便利です。

## `kubectl get all` はどのリソース情報を表示するのか

Kubernetes v1.14.3 時点で、`kubectl get all` は次のリソースが対象となっています。

- pods.v1
- replicationcontrollers.v1
- services.v1
- cronjobs.batch
- daemonsets.apps
- deployments.apps
- horizontalpodautoscalers.autoscaling
- jobs.batch
- replicasets.apps
- statefulsets.apps

見て分かるとおり、DaemonSet も Ingress も含まれていません。

## それでも kubectl get all を使いたい

ばっと大雑把にどんなリソースのオブジェクトが存在するのかを確認するのに `kubectl get all` はたしかに便利です。そこで、真に全リソースの情報を出力するには、次のワンライナが利用できます。

```sh
kubectl get "$(kubectl api-resources --namespaced=true --verbs=list -output=name | tr "\n" "," | sed -e 's/,$//')"
```

ここからはワンライナが何をやっているのかを説明します。気になる人だけ読んでください。

### 全リソースの情報を出力するワンライナの解説

```
$ kubectl api-resources --namespaced=true --verbs=list --output=name
configmaps
endpoints
events
limitranges
persistentvolumeclaims
(略...)
```

まず最初に上記のコマンドで、接続する Kubernetes API サーバで利用できる namespaced で、list に対応する全リソースの名前のみを取得しています。

`kubectl api-resources` コマンドは、接続する Kubernetes API サーバで利用できるリソースを一覧するコマンドです。ここではそのオプションである `--namespaced=true` を利用して、namespaced なリソースに絞り込んでいます。Kubernetes リソースには、namespaced とそうでないもの（cluster wide/クラスタレベル) なリソースがあり、namespaced なリソースは、Pods, Deployments などで、クラスタレベルのリソースは、Namespaces や PersistentVolumes などです。次の `--verbs=list` オプションで、リソースのリスト取得に対応しているリソースに絞り込んでいます。最後に出力する情報をリソース名だけにしています。

```
$ kubectl api-resources --namespaced=true --verbs=list -output=name | tr "\n" "," | sed -e 's/,$//'
configmaps,endpoints,events,limitranges,persistentvolumeclaims,(略...)
```

次に、`tr` と `sed` のコマンドを利用して、改行区切りの全リソースのリストをカンマ区切りに加工しています。

```
kubectl get configmaps,endpoints,events,limitranges,persistentvolumeclaims,(略...)
```

最後に `kubectl get` コマンドでリソース情報を取得しています。このコマンドは、引数にリソース名を取りますが、カンマ区切りで複数のリソースを並べて一度に取得できるため、この前の処理で全リソースのリストをカンマ区切りに加工しています。

### ワンライナを kubectl プラグインとして便利に使う

ワンライナもいいのですが、常用するとなるとスクリプトとしてまとめておくとよさそうです。ここでは単にスクリプトとせずにせっかくなので `kubectl get-all` コマンドとして利用できるように kubectl プラグインにしたいと思います。

次のステップでコマンドをインストールします。ここでは、`/usr/local/bin/` にインストールしていますが、パスが通っているディレクトリであればどこでも大丈夫です。必要に応じて変更してください。

```
cat <<EOL > /usr/local/bin/kubectl-get_all
#!/usr/bin/env bash

set -e -o pipefail; [[ -n "$DEBUG" ]] && set -x

exec kubectl get "$(kubectl api-resources --namespaced=true --verbs=list -output=name | tr "\n" "," | sed -e 's/,$//')" "$@"
EOL
chmod +x /usr/local/bin/kubectl-get_all
```

これで、真に全リソースの情報を出力する `kubectl get-all` コマンドが利用できます。

```sh
# 全リソースの情報を出力する
$ kubectl get-all

# kube-system ネームスペースの全リソースの情報を出力する
$ kubectl get-all -n kube-system
```

kubectl プラグインについての詳細は、[kubectl のプラグイン機能 kubectl plugin を使おう！](https://qiita.com/superbrothers/items/b4a0aab0575ca6d65739)を参照してください。

## まとめ

ここでは、`kubectl get all` は全リソースの情報を出力しないことと、真に全リソースの情報を出力するワンライナを紹介しました。ワンライナを kubectl プラグインとして利用できるようにしておくと何かと便利です。

次のエントリでは、`kubectl get all` で出力されるリソースはどこで指定されているのか、その仕組みについて解説します。
