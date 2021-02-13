---
title: "/usr/local/go/pkg/tool/linux_amd64/link: signal: killed"
date: 2019-06-26T08:27:41Z
draft: false
tags: ["golang", "kubernetes", "docker"]
images: ["/ogp/190626-link-signal-killed.png"]
---

## TL;DR

- メモリ不足です

## はじめに

Kubernetes のビルドなどで下記のエラーに遭遇することがあります。

```
/usr/local/go/pkg/tool/linux_amd64/link: signal: killed
!!! [0626 02:32:37] Call tree:
!!! [0626 02:32:37]  1: /go/src/k8s.io/kubernetes/hack/lib/golang.sh:715 kube::golang::build_some_binaries(...)
!!! [0626 02:32:37]  2: /go/src/k8s.io/kubernetes/hack/lib/golang.sh:854 kube::golang::build_binaries_for_platform(...)
!!! [0626 02:32:37]  3: hack/make-rules/build.sh:27 kube::golang::build_binaries(...)
!!! [0626 02:32:37] Call tree:
!!! [0626 02:32:37]  1: hack/make-rules/build.sh:27 kube::golang::build_binaries(...)
!!! [0626 02:32:37] Call tree:
!!! [0626 02:32:37]  1: hack/make-rules/build.sh:27 kube::golang::build_binaries(...)
make: *** [all] Error 1
Makefile:93: recipe for target 'all' failed
```

## 解決策

原因はメモリ不足です。Kubernetes の一部のビルドでは 8GiB のメモリが必要なことがあります。

もしラップトップなどでこのエラーに直面した場合、スペック不足かもしれません。そのほかのメモリ使用の多いプロセスを事前に殺しておくことで解決する可能性もあります。VM の場合、よりメモリの多いフレーバーを選択しましょう。

## コンテナかつ Docker Desktop なら

Docker Desktop は、Docker Engine が使用できるリソース使用量をデフォルト 2GiB に制限しています。そのため、コンテナ内のビルドでマシン自体のリソースは余っているにも関わらずこのエラーに直面した場合は、リソース使用量の制限を緩和する必要があります。macOS の場合「Preferences... → Advanced タブ」から、リソース使用量の制限値を変更できます。Kubernetes をビルドする場合は少なくとも 8GiB 以上に設定します。

![Docker Desktop で Docker Engine が利用できるリソース使用量を変更する](https://lh3.googleusercontent.com/8PzeWoLhu3pGz3V5y_e2_7chao04sj_2EaoCiLYDIIQku6LrwOtGXs9shiyMOqePWLYNKddQpVkaJmNlIkPUyZjm38r77hnYGLP2MtC_q4VNzig9N7Wml2kqfN9-lFuf9J8kFSu8fZM=w640)

当然ながら Docker Desktop の使用以外の方法でコンテナを使用している場合、これは当てはまらないことに注意してください。

## まとめ

Kubernetes をビルドする場合は、強めのマシンが必要です。Docker Desktop を使用しているなら、使用できるリソースが制限されています。必要に応じてリソース使用量の制限を緩和する必要があります。
