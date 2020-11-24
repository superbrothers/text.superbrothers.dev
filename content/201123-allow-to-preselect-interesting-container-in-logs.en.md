---
title: "kubectl logs: specify the default container to output logs"
date: 2020-11-23T11:03:15+09:00
draft: false
tags: ["kubernetes", "kubectl"]
---

If your pod contains multiple containers, running `kubectl logs` command will result in an error asking you to select one container as follows:

```
$ kubectl logs nginx
error: a container name must be specified for pod nginx, choose one of: [app sidecar]
```

Use the `--container` (`-c`) flag to specify the target container with `kubectl logs` command.

```
$ kubectl logs nginx --container app
```

However, in the case of the main container and a sidecar container configuration, the logs you probably want to see in most cases are the main container's. It is troublesome to have to specify the main container every time.

Since kubectl v1.18, you can use the `kubectl.kubernetes.io/default-logs-container` annotation to specify the default container for logs.

For example, the following Pod manifest contains two containers, `app` and `sidecar`.

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
    - 'while true; do echo $(date); sleep 1; done'
```

In this manifest, `app` container is specified in` kubectl.kubernetes.io/default-logs-container` annotation, so if you run the `kubectl logs` command without specifying a container as follows, the` app` container is selected.

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

## References

- [kubectl: allow to preselect interesting container in logs by mfojtik · Pull Request \#87809 · kubernetes/kubernetes](https://github.com/kubernetes/kubernetes/pull/87809)
