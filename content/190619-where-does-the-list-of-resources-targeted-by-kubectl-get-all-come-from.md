---
title: "kubectl get all で対象となるリソースリストはどこからやってくるのか"
date: 2019-06-19T13:37:06Z
tags: ["kubernetes", "kubectl"]
draft: false
images: ["/ogp/190619-where-does-the-list-of-resources-targeted-by-kubectl-get-all-come-from.png"]
---

## TL;DR

- Kubernetes API は、`Categories` と呼ばれるリソースが紐づくエイリアスグループがある
- `all` は、デフォルトで定義された1つのエイリアスグループである
- CustomResourceDefinition では、`spec.names.categories []string` でカスタムリソースに任意のカテゴリを設定できる
   - つまり好きなカテゴリを好きに作れるし、任意のカスタムリソースを `all` カテゴリに追加することもできる

## はじめに

[前回のエントリ](/190616-kubectl-get-all-does-not-include-most-resources)では、`kubectl get all` は全リソースの情報を表示しないことと、真に全リソースの情報を表示するワンライナの紹介と kubectl プラグインを使って便利に使う方法を紹介しました。

ここでは、その続きとして kubectl get コマンドの `all` の対象となるリソースリストがどこからやってくるのかを解説します。この情報は Kubernetes 1.14 時点で確認しているものであり、それ以降のバージョンで変更される可能性があることに注意してください。

## Kubernetes API の `Categories` フィールド

遥か昔、Kubernetes v1.6.0 まで `all` のリソースリストは、次のように kubectl コマンドにハードコードされていました。

```go
// UserResources are the resource names that apply to the primary, user facing resources used by
// client tools. They are in deletion-first order - dependent resources should be last.
// Should remain exported in order to expose a current list of resources to downstream
// composition that wants to build on the concept of 'all' for their CLIs.
var UserResources = []schema.GroupResource{
	{Group: "", Resource: "pods"},
	{Group: "", Resource: "replicationcontrollers"},
	{Group: "", Resource: "services"},
	{Group: "apps", Resource: "statefulsets"},
	{Group: "autoscaling", Resource: "horizontalpodautoscalers"},
	{Group: "batch", Resource: "jobs"},
	{Group: "extensions", Resource: "deployments"},
	{Group: "extensions", Resource: "replicasets"},
}
```

- https://github.com/kubernetes/kubernetes/blob/fbc94c089657045217999995aaf08e4025b53c52/pkg/kubectl/cmd/util/shortcut_restmapper.go#L106

しかしこの実装は、kubectl のバージョンと Kubernetes API サーバのバージョンが一致しない場合などで API サーバに `all` に含まれるリソースタイプが存在しないと、`kubectl get all` の実行が失敗してしまう問題がありました。そのため、`all` のリソースリストを kubectl にハードコードするのではなく、API サーバから提供してもらう実装に切り替えることになりました。こうすることで、API サーバは自身が提供するリソースタイプを知っているので、`all` の対象となるリソースタイプが存在しないという事態を避けられます（これとは別に kubectl に直接実装された機能をサーバサイドに持っていくという大局的な流れもあったと記憶しています）。

そこで、API サーバがサポートする Kubernetes リソースを知るための API discovery エンドポイント (e.g. `/api/v1`, `/apis/apps`) が返す各リソースに `Categories []string` というエイリアスグループを定義するフィールドが追加されました。kubectl は、`kubectl get all` が実行されると、まず `all` という名前のリソースまたはショートネーム (e.g. `po`, `deploy`) が存在しないことを確認し、もしカテゴリとして `all` が存在すれば、それに紐づくリソースタイプのリストが指定されたとして処理します[^categoryexpander]。

[^categoryexpander]: カテゴリを取得している部分のコードが気になる人は https://github.com/kubernetes/client-go/blob/v11.0.0/restmapper/category_expansion.go#L58-L88 を見ましょう。

## Pod の API リソースの定義をみてみよう

では、Pod の API リソースの定義をみてみます。これを取得するには次のコマンドを実行します。

```
$ kubectl get --raw /api/v1 | | jq '.resources[] | select(.name == "pods")'
{
  "name": "pods",
  "singularName": "",
  "namespaced": true,
  "kind": "Pod",
  "verbs": [
    "create",
    "delete",
    "deletecollection",
    "get",
    "list",
    "patch",
    "update",
    "watch"
  ],
  "shortNames": [
    "po"
  ],
  "categories": [
    "all"
  ]
}
```

`kubectl get --raw` コマンドは、引数に API サーバのパスを取り、kubeconfig の認証情報を付与してアクセスできる便利機能です。

出力された Pod の API リソース定義から、Pods は、namespaced リソースで kind は Pod、ショートネームが `po` であることなどがわかります。そのなかで `categories` フィールドが存在し `all` が含まれています。この情報から `kubectl` は Pod が `all` カテゴリに属していることを知ります。

## `all` カテゴリに属する全てのリソースタイプを取得してみよう

それでは次に接続する Kubernetes API サーバで `all` カテゴリに含まれる全てのリソースタイプを取得してみましょう。少し見にくいワンライナを使います。

```
$ kubectl version --short
Client Version: v1.14.3
Server Version: v1.14.3
$ kubectl get --raw /apis | jq -r '.groups[].versions[] | "/apis/"+.groupVersion' | cat <(echo /api/v1) - | xargs -I{} kubectl get --raw {} | jq -r '.groupVersion as $groupVersion | .resources[] | if (.categories | type == "array" and contains(["all"])) then .name + "." + $groupVersion else empty end' | sed -e 's/\/.*$//g' | sort | uniq 
cronjobs.batch
daemonsets.apps
deployments.apps
horizontalpodautoscalers.autoscaling
jobs.batch
pods.v1
replicasets.apps
replicationcontrollers.v1
services.v1
statefulsets.apps
```

`all` に含まれていそうなリソースが取得できました。このように `all` カテゴリには、Secrets や ConfigMaps も含まれていないので、`kubectl get all` が全リソースの情報を出力するわけではないことが分かります。

## カスタムリソースにカテゴリを設定する

実は、このカテゴリを自由に拡張する方法があります。 API サーバにビルトインされているリソースに新たにカテゴリを設定するには、Kubernetes のソースコードに手を入れる必要があり難しいのですが、CustomResourceDefinitions (CRD) で作成されるカスタムリソースは、CRD のスペックで好きなカテゴリを設定できます。

例えば次のような `Tako` という CRD で、このカスタムリソースは `seafoods` というカテゴリに属します。

```yaml
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: takos.stable.superbrothers.dev
spec:
  group: stable.superbrothers.dev
  versions:
  - name: v1
    served: true
    storage: true
  scope: Namespaced
  names:
    plural: takos
    singular: tako
    kind: Tako
    shortNames:
    - tk
    categories:
    - seafoods
```

このマニフェストを適用します。

```
$ kubectl apply -f tako-crd.yaml
customresourcedefinition.apiextensions.k8s.io/takos.stable.superbrothers.dev created
```

次に `tako-san` という名前でカスタムオブジェクトを作成します。

```
$ cat <<EOL | kubectl apply -f -
apiVersion: stable.superbrothers.dev/v1
kind: Tako
metadata:
  name: tako-san
EOL
tako.stable.superbrothers.dev/tako-san created
```

`takos` で `tako-san` オブジェクトが取得できるのは当然ですが、`seafoods` で取得できるのか確認します。

```
$ kubectl get takos
NAME       AGE
tako-san   92s
$ kubectl get seafoods
NAME       AGE
tako-san   96s
```

`seafoods` カテゴリを使って Tako リソースのオブジェクトが取得できました。最後に Tako リソースを `all` カテゴリにも属させてみましょう。

```yaml
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: takos.stable.superbrothers.dev
spec:
  group: stable.superbrothers.dev
  versions:
  - name: v1
    served: true
    storage: true
  scope: Namespaced
  names:
    plural: takos
    singular: tako
    kind: Tako
    shortNames:
    - tk
    categories:
    - seafoods
    - all      # <--- added
```

API resource discovery のデータはローカルにキャッシュされているので、一度削除したのち `all` カテゴリを取得してみます。

```
$ rm -rf ~/.kube/cache
$ kubectl get all
NAME                                     AGE
tako.stable.superbrothers.dev/tako-san   5m48s
```

Tako リソースが `all` カテゴリに属していることを確認できました。

## まとめ

- Kubernetes API は、`Categories` と呼ばれるリソースが紐づくエイリアスグループがある
- `all` は、デフォルトで定義された1つのエイリアスグループである
- CustomResourceDefinition では、`spec.names.categories []string` でカスタムリソースに任意のカテゴリを設定できる
   - つまり好きなカテゴリを好きに作れるし、任意のカスタムリソースを `all` カテゴリに追加することもできる

## 参考

- [Extend the Kubernetes API with CustomResourceDefinitions \- Kubernetes](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/#categories)
