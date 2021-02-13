---
title: "GNU screen から tmux に移行したついでにドットファイルも整頓した"
date: 2021-02-13T18:11:06+09:00
tags: ["tmux", "vim", "zsh", "dotfiles"]
draft: false
---

## tmux

ずっと tmux に移行しようかなという気持ちを持っていたので、重い腰を上げて移行してみた。プレフィックスを `C-j` にすれば大体 GNU screen  と同じ感じで使えることがわかったので、すんなり使えている。ただ画面の分割が GNU screen では新しい window が作られるところ、tmux では pane が作れられるのでそこに少し戸惑った。

- https://github.com/superbrothers/dotfiles/blob/master/tmux.conf

tmux プラグインでは `tmux-thumbs` が気に入っていて、vimperator 的な感じで画面内のそれっぽい文字列をハイライトしてくれて、ハイライトに出ているヒントのキーを押すとバッファにコピーしてくれる。コピーコードやトラックパッドを使うよりも高速に操作できるのでさいこう。

- https://github.com/fcsonline/tmux-thumbs

デフォルトだとコピーした文字列は tmux バッファに入ってしまうので、自分は次のように設定してクリップボードに入るようにしている。

```tmux
set -g @thumbs-command 'echo -n {} | pbcopy'
set -g @thumbs-upcase-command 'echo -n {} | pbcopy'
```

## Vim

Vim はここ最近使っていなかった言語のプラグインやらを全部削除してさっぱりした。設定自体はとくに変えてない。

- https://github.com/superbrothers/dotfiles/blob/master/vimrc

## Zsh

Zsh は `kubectl completion zsh`とかの補完の読み込みのせいで起動にめっちゃ時間がかかるようになっていてかなり苦しかった。今回の整理で 400ms 前後で起動できるようになったのでさいこう。

- https://github.com/superbrothers/dotfiles/blob/master/zshrc

これまで Zsh でプラグインマネージャを使っていなかったのだけど、使ったほうがよさそうだったので `zinit` を導入した。コマンドが自分が見慣れていない感じで最初は戸惑ったけど、慣れれば雰囲気で使えるようになった。

- https://github.com/zdharma/zinit

肝心の補完スクリプトの読み込みは `zsh-lazyload` を使って遅延させるようにした。

- https://github.com/qoomon/zsh-lazyload

次の感じで書くと、初めてコマンドが呼ばれたときに補完スクリプトが読み込まれるのでシェルの起動が早くなる。

```zsh
lazyload kubectl -- 'source <(kubectl completion zsh)'
lazyload stern -- 'source <(stern --completion=zsh)'
lazyload clusterctl -- 'source <(clusterctl completion zsh 2>/dev/null)'
lazyload kind -- 'source <(kind completion zsh; echo compdef _kind kind)'
lazyload helm -- 'source <(helm completion zsh)'
```

このプラグインを使わずとも次のようにすればよいだけなのだけど、いちいち毎回これを書かなくてもよいので使わせてもらうことにした。

```zsh
function kubectl() {
  unfunction kubectl
  source <(kubectl completion zsh)
  command kubectl "${@}"
}
```

ただ1つ問題があって、自分はプロンプトに kubeconfig のコンテキストとネームスペースを自作の [zsh-kubectl-prompt](https://github.com/superbrothers/zsh-kubectl-prompt) を使って出しているのだけど、これがなかで `kubectl` コマンドを使っているせいで補完コードが起動時に読み込まれてしまっていた。ならコンテキストなどの情報を取得するのに `kubectl` ではないコマンドを使えば補完スクリプトが読み込まれないだろうということで、`kubectl` コマンドのハードリンクを適当な名前で作ってそれを使うことで遅延読み込みが起きないようにした（シンボリックリンクだとうまく機能しなかったのでハードリンクにしてる）。`alias` にしていないのは、`no_complete_aliases` を使いたいからで、特定の `alias` だけ補完を無効化できる方法があるなら知りたい。

```zsh
command -v "$HOME/bin/kz" >/dev/null || ln "$(command -v kubectl)" "$HOME/bin/kz"
zstyle :zsh-kubectl-prompt: binary kz
```

まあ、ほとんどの人は kube-ps1 を使っているだろうけど、同じことで困っていたらそっちでも有効だと思うのでやってみてほしい。

---

シェルの起動がはやいととても気持ちが良い。起動が遅いと作業の流れがそこで切れてしまってよくなかった。今後は早い状態を維持できるようにしたい。
