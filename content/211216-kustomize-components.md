---
title: "Kustomize でベースではなくパッチを共有したいときは Component をつかう"
date: 2021-12-16T13:18:28Z
draft: false
tags: ["kubernetes", "kustomize"]
images:
- /ogp/211216-kustomize-components.png
---

## TL;DR

- Kustomize はベースを Overlay 間で共有するものだけど、パッチを共有したいこともある
- `Kustomization` を使うとパッチを共有できない
- Kustomize v3.7.0 以上で使える `Component` を使うとパッチが共有できる

## Kustomize はベースを共有する

Kustomize は Kubernetes で複数の環境、例えばプロダクションとステージングやクラスタ A、クラスタ B でほぼ同じマニフェストファイルを使うけど一部だけ違う場合に共通部分のベースと差分をオーバーレイとして管理できるツールです。

下記の例は、`base` ディレクトリに共通なマニフェストファイルがあり、`development` と `production` のディレクトリにその環境でのみ必要なマニフェストファイルや共通なマニフェストへのパッチを置き、Overlay 側から、つまり `development` から `base` を参照する形で使います。

```
~/someApp
├── base
│   ├── some_patch.yaml
│   ├── kustomization.yaml
│   └── service.yaml
├── development
│   ├── cpu_count.yaml
│   ├── kustomization.yaml
│   └── replica_count.yaml
└── production
    ├── cpu_count.yaml
    ├── kustomization.yaml
    └── replica_count.yaml
```

多くの場合でこれで十分なのですが、たまに異なるベースから Overlay、つまりパッチを共有したいことがあります。

## Kustomize でパッチを共有したい

例えば、プロダクションとステージングの2つのクラスタで若干異なるマニフェストファイルを適用したいとします。またこのマニフェストファイルは第三者が作成したもの、例えば OSS をデプロイするためのもので、リリース毎にマニフェストファイルが提供されているとします。こういった場合、私はよく次のような `Makefile` を `base` ディレクトリに配置して指定のバージョンでマニフェストファイルをダウンロードできるようにして、Overlay のプロダクションとステージングからこれを参照するという形をとります。ここでは metrics-server を例にします。

```makefile
METRICS_SERVER_VERSION ?= 3.7.0

.PHONY: update
update:
	curl -L -O https://github.com/kubernetes-sigs/metrics-server/releases/download/metrics-server-helm-chart-$(METRICS_SERVER_VERSION)/components.yaml
```

ディレクトリの構造は下記の具合です。

```
~/metrics-server
├── base
│   ├── Makefile
│   ├── components.yaml
│   │── kustomization.yaml
│   └── patches
│       └── some_patch.yaml
├── development
│   ├── kustomization.yaml
│   └── patches
│       └── some_patch.yaml
└── production
    ├── kustomization.yaml
    └── patches
        └── some_patch.yaml
```

metrics-server のマニフェストファイル `components.yaml` は外部から提供されるものなので、ダウンロードしたあとに都度手を入れると更新のたびに差分を確認しないといけなくなるので、`base` でも社内に事情に合わせて共通のパッチを用意しているとします。

これでもうまくいくのですが、困るときがあります。それはステージングだけバージョンを変えたい場合です。コンテナイメージだけを変えれば済む場合は `development` で `Kustomization` の `images` を使って変更してやれば済みますが、大きくマニフェストの構造が変わっている場合にその差分をいちいち用意していられません。

そこで、Overlay 側でそれぞれ好きなバージョンでマニフェストファイルをダウンロードするようにして、共通のパッチを Overlay 側から参照すればいいじゃんとなります。次のような感じです。

```yaml
# development/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- components.yaml
- ../base
```

```yaml
# base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
patches:
- patches/some_patch.yaml
```

ディレクトリの構造は下記の具合です。

```
~/metrics-server
├── base
│   │── kustomization.yaml
│   └── patches
│       └── somePatch.yaml
├── development
│   ├── Makefile
│   ├── components.yaml
│   ├── kustomization.yaml
│   └── patches
│       └── some_patch.yaml
└── production
    ├── Makefile
    ├── components.yaml
    ├── kustomization.yaml
    └── patches
        └── some_patch.yaml
```

しかし、これを素直にやると次のエラーになります。これは、パッチを適用する対象のオブジェクトが見つからないというもので、Kustomize はベースのマニフェストの共有はできても、Overlay の共有はできないのです。

```
$ kustomize build overlay/development
Error: accumulating resources: accumulation err='accumulating resources from '../base': '/base' must resolve to a file': recursed accumulation of path '/base': no matches for Id apps_v1_Deployment|kube-system|metrics-server; failed to find unique target for patch apps_v1_Deployment|metrics-server
```

## そこで Kustomize の Component！

ここまでは Kustomize の設定ファイルに `Kustomization` の kind を使用していましたが、Kustomize v3.7.0 から `Component` の kind が用意されており、これを `Kustomization` の代わりに使うことで Overlay を共有できます。

使い方は簡単でまずさきほどの `base/kustomization.yaml` の `kind` を `Component` に、`apiVersion` を `v1alpha1` に変更します。

```yaml
# base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Component
patches:
- patches/some_patch.yaml
```

次に `overlay/development/kustomization.yaml` で `base` を参照する際に `resources` ではなく `components` を使います。

```yaml
# development/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- components.yaml
components:
- ../base
```

これで Kustomize を実行すると、Overlay 側に存在するマニフェストに対して共通のパッチを適用できます。

```
$ kustomize build overlay/development | head
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
```

## 参考

- [Kustomize \- Kubernetes native configuration management](https://kustomize.io/)
- [Kustomize Components \| SIG CLI](https://kubectl.docs.kubernetes.io/guides/config_management/components/)
