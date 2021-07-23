---
title: Ubuntu + Intel NUC で TPM 2.0 を使って自動でルートボリュームを復号したい
date: 2021-07-23T05:16:04Z
draft: false
images:
- /ogp/210723-use-tpm-to-decrypt-the-root-volume-automatically-in-ubuntu.png
---

## はじめに

[Intel NUC を開発機として使い始めたよってエントリ](https://text.superbrothers.dev/210316-using-a-linux-server-as-a-development-environment/)でルートボリュームを暗号化しててその復号には `dropbear-initramfs` を使うとべんりと書いた。dropbear は軽量 sshd サーバでブート時にこれが起動するので SSH ログインし復号できるのでリモートからも安心してリブートできていたのだけど、そもそも Intel NUC には TPM 2.0 (Trusted Platform Module 2.0) が備わっていることをはてブのコメントにより知った。TPM があれば復号に必要な鍵を暗号化しておき、ブート時に鍵を TPM を使って複合してボリュームを復号できる。もちろん、TPM 2.0 を備えていれば Intel NUC 以外でもいける。

## Clevis のインストール

Clevis は、自動復号のためのプラガブルなフレームワークで、データや LUKS ボリュームの自動復号に利用できる。

- [latchset/clevis: Automated Encryption Framework](https://github.com/latchset/clevis)

Clevis で自動復号を実装したプラグインを PIN と呼び、ここでは TPM 2.0 を使う PIN を使用する。またボリュームの自動復号処理を実行するのにいくつか選択肢があり、1つを選択する必要がある。ここでは initramfs-tools を使うようにしたが、ほかに Dracut、UDisks2 が使える。

```
$ sudo apt update
$ sudo apt install clevis clevis-tpm2 clevis-initramfs
```

## LUKS ボリュームのバインド

Clevis で LUKS で暗号化されたボリュームをバインドする。処理としては新しく鍵を生成して、これを新しい LUKS のキーフレーズとして登録し、Clevis でこの鍵を暗号化して LUKS のヘッダ情報として暗号化した鍵を格納する。

最初に暗号化されているボリュームを確認する。ここでは `nvme0n1p3` が暗号化されている。

```
$ lsblk
NAME                                MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS
nvme0n1                             259:0    0 931.5G  0 disk
├─nvme0n1p1                         259:1    0   512M  0 part  /boot/efi
├─nvme0n1p2                         259:2    0     1G  0 part  /boot
└─nvme0n1p3                         259:3    0   930G  0 part
  └─dm_crypt-0                      253:0    0   930G  0 crypt
    └─ubuntu--vg-ubuntu--lv         253:1    0   400G  0 lvm   /
```

次にどの TPM の PCR (Platform Configuration Registers) を使うかを選択する。PCR のセットでシール（seal）することで、システムが改ざんされていない場合のみボリュームを復号化できるようになる。Intel NUC の TPM では sha256 の PCR バンクのみが使用できるよう。

```
$ sudo tpm2_getcap pcrs
selected-pcrs:
  - sha1: [ ]
  - sha256: [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23 ]
```

ここでは PCR7 を使用することにした。PCR7 はセキュアブートのポリシで、これによりセキュアブートが無効になると復号できなくなる。そのほか、各 PCR については下記で参照できる。

- https://trustedcomputinggroup.org/wp-content/uploads/PC-ClientSpecific_Platform_Profile_for_TPM_2p0_Systems_v51.pdf

正直、PCR に何を選択するのがよいのかよくわかってないので識者から教えてもらいたい🥺

Clavis でバインドするには次のコマンドを実行する。

```
$ sudo clevis luks bind -d /dev/nvme0n1p3 tpm2 '{"pcr_bank":"sha256","pcr_ids":"7"}'
Enter existing LUKS password:

```

バインドされているかどうかは次のコマンドで確認できる。

```
$ sudo clevis luks list -d /dev/nvme0n1p3
1: tpm2 '{"hash":"sha256","key":"ecc","pcr_bank":"sha256","pcr_ids":"7"}'
```

次に、今回は initramfs-tools を使って自動復号を試みる処理を選択したので、initramfs を更新する。更新後に Clevis 関連のファイルが含まれていればおそらく問題ない。

```
$ sudo update-initramfs -u -k 'all'
$ sudo lsinitramfs /boot/initrd.img-$(uname -r) | grep clevis
scripts/local-bottom/clevis
scripts/local-top/clevis
usr/bin/clevis
usr/bin/clevis-decrypt
usr/bin/clevis-decrypt-sss
usr/bin/clevis-decrypt-tang
usr/bin/clevis-decrypt-tpm2
usr/bin/clevis-luks-common-functions
usr/bin/clevis-luks-list
```

あとはリブートしてみてブート時に自動で復号されれば成功。

## LUKS ボリュームのアンバインド

アンバインドしたい場合は、次コマンドを実行する。

```
$ sudo clevis luks unbind -d /dev/nvme0n1p3 -s 1
```

---

この仕組みを入れて自動で復号されるようになったことで安心してリモートからリブートすることができるようになったが、仕組みを完全に理解しているわけではなく何か設定を変更してうまく復号できなくなったときに備えて dropbear-initramfs は入れたままにしてある。これで万が一 Clevis で復号できなかったとしても SSH でログインしてパスフレーズを入力することで復号できる。

## 参考

- [Trusted Platform Module \- ArchWiki](https://wiki.archlinux.jp/index.php/Trusted_Platform_Module)
- [Automatic LUKS volumes unlocking using a TPM2 chip \| Blog \| Javier Martinez Canillas](https://blog.dowhile0.org/2017/10/18/automatic-luks-volumes-unlocking-using-a-tpm2-chip/)
