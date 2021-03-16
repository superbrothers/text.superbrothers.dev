---
title: "リモートの Linux サーバを開発環境にする"
date: 2021-03-16T14:03:04Z
draft: false
images:
- /ogp/210316-using-a-linux-server-as-a-development-environment.png
---

これまで Macbook Pro を開発環境としていたんだけど、価格は高いし Docker for Mac は重いしでいいことないなということで Linux の開発環境に移ることにした。前職の最初の数年はすべて VM（当初は jail）にログインして開発していたのでその頃に戻った感じ。ただ GUI は macOS が何かと楽なので Intel NUC を購入してリモートでログインして使っている。Core i7、メモリ 64GB で10万ちょいと安いのにめちゃくちゃ快適でさいこう。

ここからは備忘録としてリモートを開発環境とするうえで実施した作業を残す。あと作ったものもあるので宣伝。

## 外部からログインしたい

自宅以外からも使うだろうということで（最近京都からリモートで働くこともあり）、VPN サービスとして Tailscale を導入した。

- [Best VPN Service for Secure Networks \- Tailscale](https://tailscale.com/)

はじめて使ったけど、めっちゃ楽でいい感じ。自宅にあるマシンには全て入れた。手軽すぎて特にいうことはない。解説記事は他所にあるので気になる人はそっちをみてみて。

## ルートパーティションを暗号化したい

これはリモート開発環境に関係ないのだけど、ちょいとした要件でルートパーティションを暗号化しておかないといけなかったのでその方法を書く。といっても Ubuntu 20.04 ではインストール時にルートパーティションの暗号化が選択できるので、それを有効にするだけでいい（暗号化を選択すると LVM が使われてしまう。LVM を使わないように手動でどうにかする方法もあるようなんだけど、面倒だったので標準の機能を使って暗号化した）。

ルートパーティションを暗号化するとブート時にパスワードを入力して復号化しないと OS が起動しないので、どうにかする必要がある。今回は軽量 sshd サーバの dropbear を使って initramfs がロードされた時点で dropbear を起動させて SSH ログインし、パスワードを入力して復号化するという方法を取ることにした。なお、ちょっと検索すると暗号化していない boot パーティションに復号化用の鍵を置いておいて自動で復号化するという方法がヒットするが、鍵を玄関前に置いておくようなもので意味ないのでやめよう。

Ubuntu 20.04 だと `dropbear-initramfs` パッケージをインストールするだけ。あとは使用する公開鍵を `/etc/dropbear-initramfs/authorized_keys` のファイル名で置く。最後に `sudo update-initramfs -u` で `initramfs` を更新すれば終わり。

注意する点としては dropbear が ed25519 をサポートしていないので、RSA を使わないといけない。ed25519 をサポートするパッチがあたったものもあるみたいだけど、変にハマりたくなかったので今回は素直に RSA 鍵を生成した。鍵を2つは管理したくないけど仕方がない。

リブートした際は SSH でログインして（`root` ユーザ）、次のコマンドを実行してルートパーティションを復号化すればいい。

```
cryptroot-unlock
```

外部からリブートすると復号化のタイミングで Tailscale のデーモンが起動していないので SSH ログインできなくなっちゃうんだけど、それには他のマシンから入るようにするだけでいい。適当なマシンがない場合はその辺にあるラズパイに Tailscale のエージェントを入れておくだけでよいと思う。

## リモートのクリップボードを共有したい

クリップボードの共有には clipper が簡単に使える。ローカルに立てたサーバのポートをリモートに SSH Remote forward で転送して、リモートではそのポートに書き込むことでサーバが受け取ったらクリップボードに書き込むという挙動っぽい。とくに難しいことはないが、いくつか Tips がある。インストール等は簡単なので README を参照。

- [wincent/clipper: ✂️ Clipboard access for local and remote tmux sessions](https://github.com/wincent/clipper)

clipper はサーバなので自動起動させたいわけだが、macOS の場合は Homebrew services を使えばよい。

```
$ brew services start clipper
```

デフォルトだと `localhost:8377` でリッスンし、リモートにもこのポートを転送することになる。サーバ側は他の人がいる可能性もあるので（自宅の場合はほぼないけど）、TCP は使いたくない。設定ファイルでアドレスを指定できるので Unix ドメインソケットを使うとよい。

```json
{
  "address": "~/.clipper.sock"
}
```

次に ssh_config でリモートにローカルの Unix ドメインソケットを転送する。次のような感じで設定する。

```
Host host.example.org
  RemoteForward /home/me/.clipper.sock /Users/me/.clipper.sock
```

これでリモート側の `/home/me/clipper.sock` に Unix ドメインソケットが作成されるので、これに対して次のように送信すれば `date` の実行結果がローカルのクリップボードに入るという仕組み。

```
date | socat - UNIX-CLIENT:$HOME/.clipper.sock
```

実際には上を次のように alias に設定しておけばいい。

```sh
alias pbcopy='socat - UNIX-CLIENT:$HOME/.clipper.sock'
```

これで macOS と同じ感じで使える。

```sh
$ date | pbcopy
```

ただこれだけだと SSH のセッションが閉じられてもソケットファイルが残ったままになってしまい、次ログインしてもソケットに送信できなくなる。自動的に削除するには sshd の設定に次を足すとよい。Ubuntu 20.04 では次の場所に設定ファイルを追加して sshd を再起動する。

```
# /etc/ssh/sshd_config.d/clipper.conf
StreamLocalBindUnlink yes
```

Vim のヤンクをクリップボードに書き込むのは https://github.com/wincent/vim-clipper を使えばいける。

## リモートから open コマンドで URL を開きたい

自分は `hub browse` コマンドや vim-fugitive の `Gbrowse` などでシェルから URL をブラウザで開くのを多用しているので、リモート環境で `open` コマンドを使ってローカルのブラウザで URL をどうしても開きたかった。Clipper が SSH Remote forward で Unix ドメインソケットをリモートに共有しているのをみて、同じ仕組みで URL も開けるなと思い、opener という名前で作ってみた。

- [superbrothers/opener: Open URL in your local web browser from the SSH\-connected remote environment\.](https://github.com/superbrothers/opener)

macOS だとインストールと自動起動は Homebrew でいける。

```
$ brew install superbrothers/opener
$ brew services start opener
```

サーバは `~/.opener.sock` を作るので、これを SSH Remote forward で転送するように設定する。

```
Host host.example.org
  RemoteForward /home/me/.opener.sock /Users/me/.opener.sock
```

リモート側では、`open` または `xdg-open` コマンドの偽物を `$PATH` の通る場所においておく。ここでは `~/bin` を作って `$PATH` に追加してる。

```sh
$ mkdir ~/bin
# open command
$ curl -L -o ~/bin/open https://raw.githubusercontent.com/superbrothers/opener/master/bin/open
$ chmod 755 ~/bin/open
# xdg-open command
$ curl -L -o ~/bin/xdg-open https://raw.githubusercontent.com/superbrothers/opener/master/bin/xdg-open
$ chmod 755 ~/bin/xdg-open
# Add ~/bin to $PATH and enable it
$ echo 'export PATH="$HOME/bin:$PATH"' >>~/.bashrc
$ source ~/.bashrc
```

これらのコマンドは受け取った引数を `~/.opener.sock` の Unix ドメインソケットに送信するようになっている。

あとは Clipper と同じように `StreamLocalBindUnlink yes` の設定が sshd にいるのだけど、Clipper を Unix ドメインソケットで使っていればすでに設定されているはず。

これで `hub browse` も `:Gbrowse` もうまく動く。もちろん簡単に試すには次のコマンドを実行すればいい。リモートで実行してもローカルのブラウザでページが開くはず。

```
$ open https://www.yahoo.co.jp/
```

今のところ opener には URL 以外にもなんでも書き込めるので、例えば URL 以外にもファイルを sshfs とかでローカルとリモートで同じパスでマウントしていればファイルパスを渡してもうまく動くはず。これはよさそうなのでやってみたいと思っている。
