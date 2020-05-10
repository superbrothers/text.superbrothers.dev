---
title: "CI で go mod tidy コマンドが実行されていることを確認する"
date: 2020-05-10T12:24:08+09:00
draft: false
tags: ["go"]
---

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">CI で `go mod tidy` を実行して差分が出たらコケるようにして気づかせるとかでいいだろうか。</p>&mdash; すぱぶら (Kazuki Suda) (@superbrothers) <a href="https://twitter.com/superbrothers/status/1252762835563589632?ref_src=twsrc%5Etfw">April 22, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

`go mod tidy` コマンドを実行したあとで `go.sum` ファイルに差分が出ていればエラーで終了するタスクを CI に組み込めば、実行するのを忘れていても CI で気づけます。

```bash
go mod tidy && git diff --no-patch --exit-code go.sum
```

`git diff` コマンドのオプションは、「`--no-patch` で差分を出力しない」、「`--exit-code` で差分があれば終了コードを `1` にする」です。

例えば GitHub Actions で実行する場合は次のようにします。

```yaml
name: CI
on:
  push:
    branches: [master]
    tags: ["v*"]
    paths-ignore: ['**.md']
  pull_request:
    types: [opened, synchronize]
    paths-ignore: ['**.md']
jobs:
  run:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: actions/setup-go@v2
      with:
        go-version: "~1.13.10"
    - name: Ensure go.mod is already tidied
      run: go mod tidy && git diff -s --exit-code go.sum
```
