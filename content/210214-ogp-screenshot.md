---
title: "ブログの OGP 画像にエントリのスクリーンショットを使うようにした"
date: 2021-02-14T22:37:13+09:00
draft: false
images:
- /ogp/210214-ogp-screenshot.png
tags: ["blog", "ogp", "hugo"]
---

ブログエントリの OGP 画像は、これまでエントリ中に画像を使っていればそれを指定して、特に指定できる画像がなければアバタの画像を出すようにしていたのだけど、アバダは何も表せてないので何かいいものはないかなあと思っていた。

第一候補は [@ladicle](https://twitter.com/ladicle) の [tcardgen](https://github.com/Ladicle/tcardgen) でこのツールを使うと次の感じでエントリのタイトルやタグを入れて OGP 画像を生成できる。

![tcardgen](https://github.com/Ladicle/tcardgen/raw/master/example/blog-post2.png)

これもすっごいよいのだけど、なんか他にないかなあと思っていたところ、エントリのスクリーンショットがそのまま出ていればどんなページなのか分かってよい感じなのでは？と思い、やってみた。結果としては次のような感じで個人的には気に入っている。

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">ブログエントリの ogp イメージにスクショを設定するようにしてみた。スクショは pageres-cli で生成してる。どうだろうか。 <a href="https://t.co/rOe8awTNow">https://t.co/rOe8awTNow</a></p>&mdash; すぱぶら (Kazuki Suda) (@superbrothers) <a href="https://twitter.com/superbrothers/status/1360575133308493825?ref_src=twsrc%5Etfw">February 13, 2021</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

このブログは Netlify にホストしてもらっているので、OGP 画像の生成も Netlify で HTML ファイル等を生成するときにいっしょに生成させたいのだけど、コンテナが使えなそうなので難しそうな気がしてる。できることならやりたい。

---

ここからは雑にどうやったかを紹介する。

一番大事なスクショを作成には、[pageres](https://github.com/sindresorhus/pageres-cli) を使わせてもらうことにした。次の感じで引数でスクリーンショットを撮りたい URL やサイズを指定するとスクショを作ってくれる。

```
$ pageres https://www.yahoo.co.jp/ 1200x100 --crop
```

スクショを作成できるツールはいくつかあるので、他のツールでもよいと思う。

今回 OGP 画像を生成するために書いたシェルスクリプトは次の感じで、ディレクトリ構成によってそのままでは使えないのでやってみたい人は適当に修正して使ってください。なお、Hugo で OGP 画像を指定する方法は適当に調べてほしい。

```bash
#!/usr/bin/env bash

set -e -o pipefail; [[ -n "$DEBUG" ]] && set -x

SCRIPT_ROOT="$(cd "$(dirname "$0")"; pwd)"

CONTENT_DIR="${SCRIPT_ROOT}/../content"
OGP_DIR="${SCRIPT_ROOT}/../static/ogp"
mkdir -p "${OGP_DIR}"

if ! command -v pageres >/dev/null; then
  echo "Require 'pageres' command to run this script" >&2
  echo "https://github.com/sindresorhus/pageres-cli" >&2
  exit 1
fi

# 各エントリで OGP 画像が生成されていないものだけスクショを作成する関数を定義
# 並列で OGP 画像を生成したいのでわざわざ関数にしている
function generate-ogp-image() {
  local content_file url

  content_file="$1"

  content_name="$(basename "${content_file%.*}")"
  if [[ -f "${content_name}.png" ]]; then
    echo "Skip generating ${content_name}.png because it already exists"
    return
  fi

  echo "Generating ${content_name}.png"

  if [[ "$content_name" =~ \.en$ ]]; then
    url="http://localhost:8080/en/${content_name%.*}"
  else
    url="http://localhost:8080/${content_name}"
  fi
  pageres \
    "$url" \
    # OGP 画像は 1200x630 で生成するのがいいらしいので、そのサイズを指定
    1200x630 \
    # クロップするオプション
    --crop \
    --filename="$content_name" \
    # スクショを作成するのに数秒遅延させている。遅延がないと JavaScript が実行される前に
    # スクショされてしまうことがある。
    # 自分の場合はツイートの埋め込みがうまく表示される前に作成されることがあった。
    --delay=5 \
    # 作成されたスクショをみて、フォントサイズ等を調整するのに CSS を指定する
    --css='#content { max-width: none; } html { font-size: 1.5em; }'
}
export -f generate-ogp-image

# ブログを配信するサーバをローカルで起動させる
# このあとでスクショを作成するのでバッググラウドで
make -C "${SCRIPT_ROOT}/.." serve-without-watch &
PID="$!"
# このスクリプト終了時に上記のサーバを終了させる
trap "kill $PID" EXIT

# サーバが起動してくるのを待つ
while true; do
  if [[ "$(curl "localhost:8080" -o /dev/null -w '%{http_code}\n' -s)" == "200" ]]; then
    break
  fi
  sleep 1
done

cd "${OGP_DIR}"

# 各コンテンツのファイルを引数に関数を5並列で実行する。直列だと遅い。
# pageres では複数ページのスクショを同時に撮ってくれるっぽいのだけど、
# 画像のイメージ名を個々に指定しても期待したように動いてくれなかったので、こんな感じにしてる。
find "${CONTENT_DIR}" -name "*.md" | xargs -I_ -L 1 -P 5 bash -c 'generate-ogp-image _'
# vim: ai ts=2 sw=2 et sts=2 ft=sh
```

---

今週末はやらないといけないことがあったのだけど、やる気がでなくてほかごとやっていたら終了してしまった。まあ、確定申告の準備だけはやったのでそこだけはえらいが。なんだか最近うまく調子に乗れない感じがあるのでどうにかしたい。
