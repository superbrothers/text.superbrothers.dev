---
title: "kubectl logs: デフォルトでログ出力するコンテナを指定する"
date: 2020-11-23T11:03:15+09:00
draft: false
tags: ["kubernetes", "kubectl"]
---

Pod に複数のコンテナが含まれる場合に、`kubectl logs` コマンドを実行すると次のように1つのコンテナを選択するようにとエラーになります。

```
$ kubectl logs nginx
error: a container name must be specified for pod nginx, choose one of: [app sidecar]
```

`kubectl logs` コマンドで対象のコンテナを指定するには `--container` (`-c`) フラグを使用します。

```
$ kubectl logs nginx --container app
```

しかしながら、メインのコンテナとサイドカーコンテナという構成の場合、おそらく多くの場合で確認したいログは、メインのコンテナのものです。これをいちいち毎回指定しないといけないというのも面倒です。

Kubernetes 1.18 の kubectl から、`kubectl.kubernetes.io/default-logs-container` annotation で `kubectl logs` コマンドでログ出力するデフォルトのコンテナを指定できるようになりました。

例えば次の Pod マニフェストでは、`app` と `sidecar` の2つのコンテナが含まれています。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  annotations:
    kubectl.kubernetes.io/default-logs-container: app
spec:
  containers:
  - name: app
    image: nginx
  - name: sidecar
    image: busybox
    command:
    - sh
    - -c
    - 'while true; do echo $(date); done'
```

`kubectl.kubernetes.io/default-logs-container` annotation で `app` が指定されているため、次のようにコンテナの指定なしに `kubectl logs` コマンドを実行すると `app` コンテナが選択されます。

```
$ kubectl logs nginx
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
```

## 参考

- [kubectl: allow to preselect interesting container in logs by mfojtik · Pull Request \#87809 · kubernetes/kubernetes](https://github.com/kubernetes/kubernetes/pull/87809)
