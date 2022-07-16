---
title: "kube-prometheus-stack: ダッシュボードを指定の Grafana フォルダに入れる"
date: 2022-07-16T03:17:12Z
draft: false
images:
- /ogp/220716-kube-prometheus-stack-grafana-folder.png
tags: ["kubernetes", "kube-prometheus-stack", "grafana"]
---

kube-prometheus-stack でインストールされるダッシュボードはデフォルトでは "General" にインストールされる。これを例えば "kube-prometheus-stack" という名前のフォルダにインストールしたければ次のようにする。

```yaml
grafana:
  sidecar:
   dashboards:
     folderAnnotation: grafana_dashboard_folder
     provider:
       foldersFromFilesStructure: true
```

`sidecar.dashboards.folderAnnotation` は ConfigMap に含まれるダッシュボードのデータを任意のパスに配置するための Annotation のキー名を指定する設定。

`sidecar.dashboards.provider.foldersFromFilesStructure` は、ディレクトリ名を Grafana のフォルダの名前として使う設定。

なお、この機能は Grafana Helm Chart に含まれる sidecar のもので、Grafana の機能ではない。この sidecar コンテナは任意のラベルを持つ ConfigMap をウォッチして、ConfigMap 含まれるデータを Grafana コンテナの指定のディレクトリ、デフォルトでは `/tmp/dashboards` に配置してくれるというもの。ラベルのデフォルトは `grafana_folder: "1"` となっている。

kube-prometheus-stack で生成されるダッシュボードデータを含む ConfigMap は任意の annotation を追加することができないので、仕方がなく Kustomize を使う。

```yaml
patchesJson6902:
- target:
    version: v1
    kind: ConfigMap
    name: ".*"
    labelSelector: grafana_dashboard=1
  patch: |
    - op: add
      path: /metadata/annotations
      value:
        grafana_dashboard_folder: /tmp/dashboards/kube-prometheus-stack
```

---

全くブログを更新できていないので、家のラズパイクラスタでやっている細々した作業をエントリにしていくことにしていこうかなと思ったけど、これだけ書くにもそれなりに時間がかかるので悩ましい。
