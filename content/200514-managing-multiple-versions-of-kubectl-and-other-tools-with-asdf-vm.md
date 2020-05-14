---
title: "複数バージョンの kubectl や他の CLI ツールを管理するには asdf-vm を使う"
date: 2020-05-14T09:08:10+09:00
draft: false
---

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">asdf がそれっぽいツールですね。私はこれで kubectl を管理してます。</p>&mdash; すぱぶら (Kazuki Suda) (@superbrothers) <a href="https://twitter.com/superbrothers/status/1260716343336112131?ref_src=twsrc%5Etfw">May 13, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

kubectl などの CLI ツールを複数のバージョンを切り替えながら使いたいことがあります。例えば本番のクラスタのバージョンは 1.16 だけど検証で 1.18 のクラスタを使うといったケースです。毎回どこからインストールするのかドキュメントを探したり、コマンドのヒストリを検索してみたり、`kubectl118` のような別名で管理したりと何かと面倒です。

asdf-vm は、Node.js や Ruby、Python、Go といった言語で複数のバージョンを管理できる anyenv に似たツールで、言語に留まらず kubectl や istioctl といった CLI ツールもいい感じにインストールからバージョンの切り替えなどの管理ができます。asdf-vm のインストール手順は[ドキュメント](https://asdf-vm.com/#/core-manage-asdf-vm)をみてもらうとして、指定のバージョンの kubectl をインストールする流れを紹介します。

最初に kubectl の asdf プラグインをインストールします。プラグインをインストールすることで管理対象の CLI を追加できます。

```
$ asdf plugin-add kubectl https://github.com/Banno/asdf-kubectl.git
```

次にどのバージョンが使えるのかを確認します。

```
$ asdf list-all kubectl
1.14.10
1.15.8
1.15.9
1.15.10
1.15.11
...
```

次に指定のバージョンの kubectl をインストールします。ここでは `1.18.2` です。

```
$ asdf install kubectl 1.18.2
Downloading kubectl from https://storage.googleapis.com/kubernetes-release/release/v1.18.2/bin/darwin/amd64/kubectl
```

最後に kubectl に 1.18.2 を使うようにします。

```
$ asdf global kubectl 1.18.2
$ kubectl version --client
Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.2", GitCommit:"52c56ce7a8272c798dbc29846288d7cd9fbae032", GitTreeState:"clean", BuildDate:"2020-04-16T11:56:40Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"darwin/amd64"}
```

もし他のバージョンを使いたければ同じ手順でインストールして切り替えられます。

そのほか、asdf-vm には kubectl 以外にも多くのプラグインがあり、Go や Node.js といった言語も私は asdf-vm で管理するようになりました。プラグインリストに登録されているものは、次のコマンドで確認できます。

```
$ asdf plugin-list-all
```

2020年5月14日時点で、194 のプラグインが登録されています（`asdf plugin-list-all | wc -l`）。リストに登録されていないプラグインもあるので、そのときは `asdf-<tool name>` で検索すると見つかることがあります。

自動補完がサポートされているのも推しポイントです。asdf-vm を使う際は必ず設定しましょう。

- [asdf vm \- An extendable version manager](https://asdf-vm.com/#/)

---

asdf-vm めっちゃ便利でもうこれなしだとツラいです。プラグインをとても簡単に開発できるのもよいですね。私も `tridentctl` という CLI ツールのプラグインを書きました。ほぼ同じスクリプトで他のツールにも対応できるので、もし使いたいツールのプラグインがなければ作ってみてください。

- https://github.com/superbrothers/asdf-tridentctl
