---
title: "M2 MacBook Air を購入してデュアルディスプレイしてる"
date: 2022-08-10T03:14:11Z
draft: false
images:
- /ogp/220810-m2-macbook-air.png
tags:
- diary
- macOS
---

![M2 MacBook Air](https://lh3.googleusercontent.com/pw/AL9nZEUha3xycrPxeH0I6mcohwYfr3bvvicr2MxENnHs0ZSIDvkHZVkT-SBStaWRjEDBjytgYwYnSZR--m2tHF48Shz0_o7LKdxwZWciJy43LK42-l-xHfEdrZszSJTW22tHXOxgCBvE71MJnMD2GzC0fUYGGA=w900)

[M2 MacBook Air](https://www.apple.com/jp/macbook-air-m2/) を次のスペックで購入した。

- ミッドナイト
- 8コア CPU、8コア GPU、16コア Neural Engine 搭載 Apple M2 チップ
- 16GB ユニファイドメモリ
- 512GB SSD ストレージ

"[リモートの Linux サーバを開発環境にする](/210316-using-a-linux-server-as-a-development-environment)"に書いたように、最近主な開発は Intel NUC のサーバ上でやっていて、ラップトップはデスクトップ用途のみになっているので Air で十分だろうと判断した。以前はローカルでも開発してたので Intel MacBook Pro 16インチを使っていたんだけど、在住の京都から東京への移動に16インチのラップトップを持っていくのが重くてツラかった。肩がこる。

M1 を使ったことがないのでそれとの差はわからないけど、今のところめちゃくちゃ快適でびびってる。筐体の剛性が高い感じもかなりいい感じ。唯一、外部ディスプレイを1枚までしかつなげないという問題があって、これは購入後にセットアップしていて2枚目に出力されない理由を調べていたときに知った。M1 も同じみたいなんだけど、M1 は全く検討していなかったので知らなかった。M1 では DisplayLink という技術に対応したドックを使えば2枚出力もいけるということだったので、おそらく M2 でもいけるだろうとさっそく購入してみたら2枚に出力できた。

DisplayLink 対応のドックといっても 4K または HD 2枚のサポートだったり、8K または 4K 2枚のサポートだったり色々あるようで、4K 2枚をサポートしているほうが高い。今回購入したのが25000円もしてただディスプレイ2枚に出力したいがためだけに正気か？とも思ったけど、1枚ではやっていけないので仕方がない。USB ポートがないモデルだったりもっと安いのもあるんだけど、翌日届くのがこれしかなかった。どうやら円安だったり半導体不足だったりで以前より高くなっているらしい。

- [Amazon\.co\.jp: WAVLINK USB\-C Ultra 5Kユニバーサルドッキングステーションデュアル4Kドッキングステーション 60W PD付き（HDMIとDisplay ×2セット、ギガビットイーサネット、USB Cx2、USB 3\.0x4、オーディオ、マイク） : 家電＆カメラ](https://www.amazon.co.jp/gp/product/B083332JMB/)

このドックで問題なく2枚の出力はできたのだけど、そのうち一枚のディスプレイ（DELL U2720Q）で 3008x1692 を HiDPI で出力できなくなる問題があった。ドックを介さずに直接接続すれば HiDPI で出力されるので DisplayLink を使うとダメになるらしい。先駆者により、"Better Display" というアプリを使ってダミーのディスプレイを作成して、これを実際にディスプレイからミラーするという方法を取るといけるとあったのでやってみたらいけた。ただ、ミラーを経由してるからか直接接続した際の HiDPI と比べて若干ボケてる気がしなくもない。無視できる程度ではある。Better Display は有償のアプリだけど無料期間があるので同じことやりたい人は試してみるといい。設定は次の Reddit の投稿にある手順でいけた。DisplayLink のフォーラムにも手順があったがそれではうまくいかなかったので注意。

> - 1 - Start the program. BetterDummy icon will show up on the top bar.
> - 2 - Click to BetterDummy icon. Then create a new dummy that fits to your external monitor's screen ratio. It is most probably > 16:9.
> - 3 - Go to "System Preferences" -> "Displays" -> "Display Settings". On the left hand side of the window your physical monitors + a dummy screen should be listed.
> - 4 - Select your physical external screen from the list.
> - 5 - Click to "Use as". Select "Mirror for dummy 16:9" from the list. Your monitor will probably flash for a second.
> - 6 - Click to "Scaled" under "Resolution". Choose whichever retina setting you like.

- [This is why your external monitor looks awful on an M1 Mac : apple](https://www.reddit.com/r/apple/comments/raaw9e/comment/hni78zq/?utm_source=share&utm_medium=web2x&context=3)

Better Display のインストールは Homebrew Cask でいける。

```
brew install betterdisplay
```

- [waydabber/BetterDisplay: Unlock your displays on your Mac\! Smooth scaling, HiDPI unlock, XDR/HDR extra brightness upscale, DDC, brightness and dimming, dummy displays, PIP and lots more\!](https://github.com/waydabber/BetterDisplay)

DisplayLink + Better Display でスリープから復帰したときに表示がおかしくなることがあるが、スリープから復帰する前にすべてのディスプレイの電源を入れてからスリープから起こしてやるとおかしくならないことが多い気がする。おかしくなったら再起動してやると直る。

そのほか、Raycast がたまにハングする（プロセスを殺して対応）、Google 日本語入力の文字入力が遅くなる（再起動で対応）問題が残ってるんだけど、それにしても M2 MacBook Air はディスプレイ1枚までしか出力できないという大きな問題があるもののとても満足している。

---

最近ねこゲーの Stray をやって楽しかった。ゲームは普段そこまでやらないのだけど、たまにやると楽しくて一度始めるやり切らないと気が済まなくなる。Stray のなかに出てくるロボットの描いてある絵がほしいかもしれない。売って欲しい。
