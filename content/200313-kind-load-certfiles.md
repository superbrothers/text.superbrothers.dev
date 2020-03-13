---
title: "kind で作成したクラスタに中間証明書をインストールする"
date: 2020-03-13T10:52:32+09:00
draft: false
tags: ["kubernetes", "kind"]
---

コンテナイメージの取得に「x509: certificate signed by unknown authority」エラーで失敗する場合、中間証明書がインストールされていないことが考えられます。kind で作成したクラスタの場合で発生した場合にも中間証明書を各ノードにインストールする必要がありますが、kind にはそれ専用のコマンドが用意されていないため、各ノードで次の手順を実行する必要があります。ノードの一覧は `kind get nodes` で取得できます。

1. 中間証明書をノードの `/usr/local/share/ca-certificates/` に転送する
    - `docker cp *.crt <node>:/usr/local/share/ca-certificates/`
2. 転送した中間証明書を読み込む
    - `docker exec <node> update-ca-certificates`
3. containerd を再起動する
    - `docker exec <node> systemctl restart containerd`

正常に中間証明書がインストールされているかどうかは、ノード内でコンテナイメージを取得できるかを確認するのが早いです。

```
docker exec <node> crictl pull <container-image>
```

上記のコマンドを kind でクラスタを作成するごとに実行するのは面倒なので、kind クラスタの全ノードで上記の手順を実行する簡単なスクリプトを作成しました。よければ使ってください。

```
curl -L -O https://gist.githubusercontent.com/superbrothers/9bb1b7e00007395dc312e6e35f40931e/raw/7c9f99930f2c21b075349378f273db293ec2697e/kind-load-certfile
chmod +x ./kind-load-certfile
./kind-load-certfile [-n name] *.crt
```

- https://gist.github.com/superbrothers/9bb1b7e00007395dc312e6e35f40931e

---

鬼伝説の New 富浦 IPA (New England IPA) がめっちゃ美味しかったです。おすすめ。

<blockquote class="twitter-tweet" data-conversation="none"><p lang="ja" dir="ltr">New 富浦 IPA, うまい。 <a href="https://t.co/cRJH0BAEdF">pic.twitter.com/cRJH0BAEdF</a></p>&mdash; すぱぶら (Kazuki Suda) (@superbrothers) <a href="https://twitter.com/superbrothers/status/1238021745849724929?ref_src=twsrc%5Etfw">March 12, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
