---
title: "[Cluster API] clusterctl コマンドにシェル自動補完機能を追加しました（v0.3.10）"
date: 2020-10-02T09:43:20+09:00
tags: ["kubernetes", "cluster-api"]
draft: false
images: ["/ogp/201002-clusterctl-completion-command.png"]
---

Cluster API v0.3.10 で CLI ツールである `clusterctl` にサブコマンドとフラグのシェル自動補完機能を追加しました。

- [Release v0\.3\.10 · kubernetes\-sigs/cluster\-api](https://github.com/kubernetes-sigs/cluster-api/releases/tag/v0.3.10)

次の手順で使用できます。

```
$ clusterctl version
clusterctl version: &version.Info{Major:"0", Minor:"3", GitVersion:"v0.3.10", GitCommit:"af6630920560ca0e12179897b96d6ea8bd830b63", GitTreeState:"clean", BuildDate:"2020-10-01T14:30:28Z", GoVersion:"go1.13.15", Compiler:"gc", Platform:"darwin/amd64"}

# For bash
$ source <clusterctl completion bash)

# For zsh
$ source <clusterctl completion zsh)
```

正しく有効になっていれば `<tab>` で補完されます。

```
$ clusterctl <tab>
completion  config      delete      generate    get         init        move        upgrade     version
```

v0.3.10 時点では、サブコマンドとフラグのみの補完がサポートされています。今後、kubectl コマンドでの Pod 名の補完のような動的な補完もサポートしていきます。

そのほか、詳しい情報は、下記ドキュメントを参照してください。

- [completion \- The Cluster API Book](https://cluster-api.sigs.k8s.io/clusterctl/commands/completion.html)

---

これで少しだけオペレーションが楽になるぞ！
