---
title: "My First Post"
date: 2019-03-24T00:22:11Z
draft: false
---

<blockquote class="twitter-tweet" data-lang="en"><p lang="ja" dir="ltr">昨日飲んでめっちゃよかったので😊 / いぬいっぴき <a href="https://t.co/PniMULOKcg">pic.twitter.com/PniMULOKcg</a></p>&mdash; Kazuki Suda / すぱぶら (@superbrothers) <a href="https://twitter.com/superbrothers/status/1107963277684817924?ref_src=twsrc%5Etfw">March 19, 2019</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

dev ドメインを取得したのに、何にも利用していなかったので、Netlify を利用してみたい気持ちも同時に叶えるべくブログを作りました。

<blockquote class="twitter-tweet" data-lang="en"><p lang="ja" dir="ltr">dev ドメイン取得したからなにかに使いたい → ブログでも作ろう → そういえば Netlify を使ってみたかった → Hugo を使おう → テーマどれにしよう → うーん →Hugo テーマの作り方を調べてる</p>&mdash; Kazuki Suda / すぱぶら (@superbrothers) <a href="https://twitter.com/superbrothers/status/1109287944420884481?ref_src=twsrc%5Etfw">March 23, 2019</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

テーマは自作する気持ちだったんですが、結果的には理想に近いものがあったのでそれを利用しました。



## Hugo

Hugo は社内ドキュメントを提供するのに使ったことがあったので、特に苦労せずに使い始められました。サイトのビルドやプレビューには、`Makefile` を利用しています。繰り返し使うような決まったコメントの実行には、普段から `Makefile` にまとめるようにしています。

```makefile
DOCKER_RUN := docker run --rm --init -v $(shell pwd):/src -w /src -u $(shell id -u):$(shell id -g)
HUGO_VERSION := 0.53
HUGO_IMAGE := jojomi/hugo:$(HUGO_VERSION)
HUGO ?= $(DOCKER_RUN) -p 8080:8080 $(HUGO_IMAGE) hugo

.PHONY: build
build:
                $(HUGO)

build-dev:
                $(HUGO) -D

.PHONY: serve
serve:
                $(HUGO) server --bind=0.0.0.0 -p 8080

.PHONY: serve-dev
serve-dev:
                $(HUGO) server -D --bind=0.0.0.0 -p 8080

.PHONY: new-post
new-post:
                @yymmdd="$$(date +%y%m%d)"; \
                echo -n "content/posts/$${yymmdd}-POST.md: "; \
                read post; \
                $(HUGO) new "content/posts/$${yymmdd}-$${post}.md"

.PHONY: run-in-hugo
run-in-hugo:
                $(DOCKER_RUN) -it $(HUGO_IMAGE) /bin/sh
```

`hugo` コマンドは、Docker コンテナ内で実行するようにしてローカルにコマンドのインストールを不要にしています。このパターンは、よく見かけるようになりましたが、自分も便利なのでよく利用しています。

ただ、Netlify でサイトをビルドするときには、これだけではうまくいかないので、それについては後述します。

## Hugo テーマ

よくよく [Complete List \| Hugo Themes](https://themes.gohugo.io/) を眺めていたら [Hugo Paper \| Hugo Themes](https://themes.gohugo.io/hugo-paper/) がよさそうだったので、それを利用させてもらうことにしました。

Hugo テーマとして利用者がカスタマイズする余地があるように作られているのが一般的なのかなと思っていますが、このテーマはその余地がないようだったので、[Partial Templates \| Hugo](https://gohugo.io/templates/partials/#example-header-html) を参考に[パッチ](https://github.com/superbrothers/text.superbrothers.dev/commit/cc4721cdee04bdbe858a5f8e61e31111f4e1308c)を当てています。この辺りは、Hugo として統一されたルールがあると迷わずに済むと思うんですが、存在しないんでしょうか。マージされるかわからないですが、このパッチはあとで PR として送ってみることにします。

カスタマイズした内容は、日本語フォントの指定とコードブロックのフォントに [Hack](https://sourcefoundry.org/hack/) の利用、ページタイトルへの `#` の追加になりました。

## netlify

[netlify](https://www.netlify.com/) は、kubernetes.io で使われていることで以前から知っていたので個人的にも使ってみたいなと思っていました。GitHub Pages と何が違うのかよく分かっていなかったのですが、GitHub Pages はスタティックファイルをホストできるだけなので、サイトをビルドする必要がある場合は、どこかの CI システムで事前にビルドする必要があります。Netlify は、サービス自体にサイトをビルドするフェイズが組み込まれているので、個別に CI を利用する必要がなく便利でした。

そのほかにも豊富に機能があるようなので、時間を見つけて眺めてみようかと思います。

### netlify のビルド環境

netlify のビルド環境では、Docker が利用できないようです。今回 `hugo` コマンドはコンテナ内で利用するようにしていたため、このままではうまくいきません。`Makefile` で `hugo` コマンドを上書きできるようにして、netlify のビルド環境では環境にインストールされた `hugo` コマンドを利用するようにすれば大丈夫です。

```toml

[build]
publish = "public"
command = "make build"

[build.environment]
HUGO = "hugo"
HUGO_VERSION = "0.53"
```

---

場所ができたので、今後技術に限らずいろいろ書いていこうかなという気持ちです。続くといいな。

- [superbrothers/text\.superbrothers\.dev](https://github.com/superbrothers/text.superbrothers.dev/blob/master/netlify.toml)