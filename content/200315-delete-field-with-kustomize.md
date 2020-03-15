---
title: "Kustomize でマニフェストのフィールドを削除する"
date: 2020-03-15T10:09:27+09:00
draft: false
tags: ["kubernetes", "kustomize"]
---

対象のフィールドの値を `null` としてパッチすることでフィールドそのものを削除できます。

---

例えば次のような Pod マニフェストがあるとします。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod
spec:
  containers:
  - name: test-container
    image: k8s.gcr.io/busybox
    command: [ "/bin/sh", "-c", "env" ]
    env:
    - name: LOG_LEVEL
      valueFrom:
        configMapKeyRef:
          name: env-config
          key: log_level
  restartPolicy: Never
```

このマニフェストの環境変数 `LOG_LEVEL` は ConfigMap から値を取得するように設定されていますが、これを直接 `INFO` に設定したい。つまり次のように `env.value` フィールドを値を `INFO` として新たに追加し、既存の `env.valueFrom` フィールドを削除したいとします。

```diff
--- a/pod.yaml
+++ b/pod.yaml
@@ -9,8 +9,5 @@ spec:
     command: [ "/bin/sh", "-c", "env" ]
     env:
     - name: LOG_LEVEL
-      valueFrom:
-        configMapKeyRef:
-          name: env-config
-          key: log_level
+      value: INFO
   restartPolicy: Never
```

ここで次のような `$patch :delete` を使用して `env.valueFrom` フィールドを削除しようとしますが、

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- pod.yaml
patchesStrategicMerge:
- |-
  apiVersion: apps/v1
  kind: Pod
  metadata:
    name: dapi-test-pod
  spec:
    containers:
    - name: test-container
      env:
      - name: LOG_LEVEL
        value: INFO
        valueFrom:
          $patch: delete
```

値は消えてもフィールド自体は残ってしまい、これをそのまま適用しようとしてもバリデーションエラーになります。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod
spec:
  containers:
  - command:
    - /bin/sh
    - -c
    - env
    env:
    - name: LOG_LEVEL
      value: INFO
      valueFrom: {}  # <-------- Here
    image: k8s.gcr.io/busybox
    name: test-container
  restartPolicy: Never
```

ここでは削除したい対象のフィールドの値を `null` でパッチすることで、

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- pod.yaml
patchesStrategicMerge:
- |-
  apiVersion: v1
  kind: Pod
  metadata:
    name: dapi-test-pod
  spec:
    containers:
    - name: test-container
      env:
      - name: LOG_LEVEL
        value: INFO
        valueFrom: null
```

フィールドそのものも削除できます。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod
spec:
  containers:
  - command:
    - /bin/sh
    - -c
    - env
    env:
    - name: LOG_LEVEL
      value: INFO
    image: k8s.gcr.io/busybox
    name: test-container
  restartPolicy: Never
```
