---
title: "kubectl sort-manifests プラグイン: マニフェストファイルを適切なインストール順序に並び替える"
date: 2019-05-12T03:06:24Z
tags: ["kubernetes", "kubectl plugin"]
images: ["/ogp/190512-kubectl-sort-manifests-plugin.png"]
---

19年4月22日に開催した Kubernetes Meetup Tokyo #18 でメルカリでの Kubernetes マニフェストの管理とオペレーションについて話してもらいました。そのなかで「Kubernetes マニフェストファイルを適用すべきファイルの順序をどのように取得して、実際にどう適用するか」という話がありました。

<script async class="speakerdeck-embed" data-slide="92" data-id="f3872035e1134d988dc8d5c192ef6549" data-ratio="1.77777777777778" src="//speakerdeck.com/assets/embed.js"></script>

## なぜマニフェストを適切な順序でソートしなければいけないのか

例えば Namespace オブジェクトが含まれるマニフェスト群を次のようなコマンドで適用するとします。

```
$ kubectl apply -f manifests/
```

この場合、`kubectl apply` コマンドが `manifests` ディレクトリに含まれるファイルをファイル名順（降順）でソートし適用します。Namespace オブジェクトは、基本的に1番最初に適用されないと、他のオブジェクトが属する Namespace が作成されていない状況になるため、適用に失敗してしまいます。そのほかにも ConfigMap オブジェクトはそれを利用する Deployment オブジェクトが適用される前に作成される必要があります。

この問題には、`000-namespace.yaml` といった Apache httpd の設定ファイルでよく見られるようなファイル名にプレフィックスをつけて適用順を指定するようなテクニックが利用できます。そのほかに1つのマニフェストファイルに複数のオブジェクトを記述（YAML のマルチドキュメント形式）しても記述された順序で適用されます。このやり方のほうが一般的かもしれません。ただ適切な順序があるのであれば、人間が気にすべき問題ではないので、自動的にソートしてもらいたいものです。

上記の発表資料にもあるとおり、Helm では適切な順序がソート関数として定義されていて、その順序に自動的にソートされるようになっています。また Kustomize でも似たような関数が定義されていて適切な順序にソートされます。そのため、今では多くの人がそのどちらかのツールを利用していると思うので、あまり気にする必要はないのですが、使っていなくても自動的にソートできる `kubectl sort-manifests` という kubectl プラグインを作りました。

- [superbrothers/ksort: Sort manfest files in a proper order by Kind](https://github.com/superbrothers/ksort)

作りましたというのは実際には正しくなくて、数年前にほしいなと思い実装していたのですが、上記の発表をみて少しは需要がありそうなのかなと思い、kubectl プラグイン形式で利用できるようにしました。リポジトリ名が ksort となっていますが、これは kubectl プラグインの仕組みができる前に実装した際にその名前にしたためです。

## kubectl sort-manifests プラグイン

`kubectl sort-manifests` は、適用されるべき順序にマニフェストをソートしてくれるプラグインが、マルチドキュメントのマニフェストファイルであっても、そのなかのオブジェクトも含めソートするようになっています。

使い方は簡単で、kubectl と同様に `--filename` (`-f`) オプションでマニフェストファイルまたはディレクトリを1つまたは複数指定するだけです。実行すると結果として標準出力にソートしたマニフェストを出力します。

*v0.2.0 で kubectl の UX に合わせるべく、引数によるマニフェストファイルまたはディレクトリの指定を廃止し、`--filename` (`-f`) オプションによる指定に変更しました。*

```
kubectl sort-manifests -f manifests/
# Source: manifests/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap
data:
  (略)
---
# Source: testdata/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
(略)
```

次のようにファイルとディレクトリを同時に指定もできます。

```
kubectl sort-manifests -f manifests/ -f namespace.yaml -f deployment.yaml
```

ソートした結果を適用する場合は、次のようにします。

```
kubectl sort-manifests -f manifests/ | kubectl apply -f-
```

### インストール方法


`kubectl sort-manifests` は kubectl plugin マネージャである krew でインストールできます。

```
kubectl krew install sort-manifests
```

krew のインストール方法は、下記リポジトリの README を参照してください。

- [kubernetes\-sigs/krew: 📦 Package manager for "kubectl plugins"](https://github.com/kubernetes-sigs/krew)

このコマンドを単体で利用したい場合は、GitHub Releases にアーカイブファイルをアップロードしているので、そこからインストールできます。この場合は、コマンド名がオリジナルの `ksort` となっていることに注意してください。

- [Releases · superbrothers/ksort](https://github.com/superbrothers/ksort/releases)

## まとめ

Kubernetes マニフェストには適用すべき順序があります。Helm または Kustomize を利用している場合は自動的に適切な順序にソートしてくれるので、気にする必要はありません。もしそれらのツールを利用していないけど、マニフェストはいい感じにソートしたい場合は、`kubectl sort-manifests` プラグインの利用を検討してみてください。

また Kubernetes Meetup Tokyo #18 のそのほかの発表も含め YouTube で配信動画を公開しています。ぜひ参照してみてください。

- [Kubernetes Meetup Tokyo \#18 \- YouTube](https://www.youtube.com/watch?v=5NL1tEIcU-o)

## 参考

- [Kubernetes Meetup Tokyo \#18 \- connpass](https://k8sjp.connpass.com/event/124114/)
- [Kubernetes manifests management and operation in Mercari \- Speaker Deck](https://speakerdeck.com/b4b4r07/kubernetes-manifests-management-and-operation-in-mercari)
- [superbrothers/ksort: Sort manfest files in a proper order by Kind](https://github.com/superbrothers/ksort)
- [kubernetes\-sigs/krew: 📦 Package manager for "kubectl plugins"](https://github.com/kubernetes-sigs/krew)
- [helm/helm: The Kubernetes Package Manager](https://github.com/helm/helm)
- [kubernetes\-sigs/kustomize: Customization of kubernetes YAML configurations](https://github.com/kubernetes-sigs/kustomize/)

---

GW中にちょこちょこ作業した成果をエントリにしてみました。こういう小さいやつをもう少し頻度高く書けるといいかな。
