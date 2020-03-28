---
title: "Docker/Kubernetes で PID 1 問題を回避する"
date: 2020-03-28T12:34:05+09:00
draft: false
tags: ["kubernetes", "docker"]
---

## はじめに

PID 1 問題というのは、コンテナを実行した際にアプリケーションのプロセスが PID 1（プロセス番号が1番）で実行されることで、コンテナに対して SIGTERM などのシグナルを送信してもコンテナ内のプロセスが正常に終了しないというものです。ここでは2020年3月現在でこの PID 1 問題を回避する方法を Docker と Kubernetes のそれぞれで紹介します。

## TL;DR

- アプリケーションが「明示的にシグナルをハンドリングするようにする」、または「PID 1 で実行されないようにする」の2つの回避策がある
- アプリケーションプロセスが PID 1 で実行されないようにする場合、Docker では Tini のような軽量 init を使う、もしくは Docker 1.13 以上の場合は `docker run` の `--init` オプションを使うで問題を回避できる
- Kubernetes では Pod shareProcessNamespace を使うことで問題を回避できる

## PID 1 問題とは

そもそもなぜこの問題が起きるのかについては、2016年3月に開催された Docker Meetup Tokyo #6 の LT で紹介したスライドがあるため、詳細はそちらで見てください。簡単にいうと PID 1 のプロセスは Linux カーネルに特別扱いされていて、そのプロセス自身が明示的に送信されたシグナルをハンドリングしていない場合それを無視します。コンテナの場合、アプリケーションのプロセスが PID 1 で実行されることが多いため、アプリケーションが明示的にシグナルをハンドリングしていないとシグナルを送信しても無視されてしまい、コンテナに SIGTERM を送っても無視されて終了しないということが起こります。

<script async class="speakerdeck-embed" data-id="bc4f9d0bd7184379831c699e17da8592" data-ratio="1.77777777777778" src="//speakerdeck.com/assets/embed.js"></script>

PID 1 問題を実際に確認するために Node.js で実行される HTTP サーバを含むコンテナイメージを用意しました。次のようにコンテナを実行して、コンテナに対して SIGTERM を送ってみます。

```
docker run -d --rm --name node-hello docker.io/superbrothers/node-hello

docker exec node-hello ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.9  1.3 589700 28100 ?        Ssl  05:01   0:00 node index.js
root        13  0.0  0.1  36636  2600 ?        Rs   05:01   0:00 ps aux

docker kill -s TERM node-hello

docker ps
CONTAINER ID        IMAGE                      COMMAND                  CREATED             STATUS              PORTS                       NAMES
6ab8821e98b3        superbrothers/node-hello   "docker-entrypoint.s…"   23 seconds ago      Up 22 seconds                                   node-hello
```

SIGTERM を送信してもコンテナが終了していないことが確認できます（プロセスが SIGTERM を受け取った場合のデフォルトの挙動は終了です）。

では、PID 1 問題の回避策をみていきます。アプリケーションが「明示的にシグナルをハンドリングするようにする」、または「PID 1 で実行されないようにする」の2つです。

## Docker で PID 1 問題を回避する

「明示的にシグナルをハンドリングするようにする」という回避策では、これは個々のアプリケーションでやってくださいということになるのですが、言語によって簡単に対処できることもあります。例えば Node.js の場合、SIGTERM をデフォルトではハンドリングしていないため、PID 1 問題が発生しますが、`npm start` 経由でアプリケーションを実行することでこの問題を回避できます。それは npm がシグナルを明示的にハンドリングするようになっているからです。

```dockerfile
FROM node:13
...
CMD ["npm", "start"]
```

このようにアプリケーションが直接この問題に対処すればどこであっても問題が発生しません。このほかにアプリケーションで簡単に対処できない場合は、[Tini](https://github.com/krallin/tini) のような一般に軽量 init と呼ばれるものが使用できます。使い方は簡単で、コンテナイメージをビルドする際にインストールして、`ENTRYPOINT` で Tini を実行するようにするだけです。

```dockerfile
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

CMD ["/your/program", "-and", "-its", "arguments"]
```

これでアプリケーションが Tini 経由で実行され、Tini がシグナルをハンドリングしてくれるため、PID 1 問題を回避できます。また、Docker 1.13 以上では `docker run` コマンドの `--init` オプションを使用すると、Docker が勝手に Tini 経由でアプリケーションを実行してくれます。

```
docker run --rm -d --init --name node-hello docker.io/superbrothers/node-hello

docker exec node-hello ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.1  0.0   1052     4 ?        Ss   04:24   0:00 /sbin/docker-init -- docker-entrypoint.sh node index.js
root         7  0.7  1.4 589724 29068 ?        Sl   04:24   0:00 node index.js
root        15  0.0  0.1  36636  2716 ?        Rs   04:24   0:00 ps aux

docker kill -s TERM node-hello

docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```

`docker run` コマンドを直接使用してコンテナを利用することが分かっている場合は `--init` オプションを利用するのがもっとも簡単です。

## Kubernetes で PID 1 問題を回避する

Kubernetes でこの問題を回避する場合、アプリケーションがそもそもシグナルを明示的にハンドリングしていれば何もする必要はありません。Node.js の場合は `npm start` を使うといった具合です。また、軽量 init を使うことももちろん有効です。しかし、自分たちで開発するアプリケーションならまだしも既存のコンテナイメージでこの問題がある場合にこれらの対処方法を取るのは面倒です。`docker run` コマンドの `--init` オプションが使えればよいのですが、Kubernetes はこのオプションをサポートしていません。

そこで Kubernetes で 1.17 から GA になった [Share Process Namespace](https://kubernetes.io/ja/docs/tasks/configure-pod-container/share-process-namespace/) が利用できます。この機能は Pod に含まれる複数のコンテナで PID ネームスペースを共有し、Pod に含まれるコンテナのプロセス間でシグナルを送信できるようにするための機能ですが、PID 1 問題を回避するためにも利用できます。

まずは Share Process Namespace を使用せずに Pod を作成してみます。

```
$ kubectl version
Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.0", GitCommit:"9e991415386e4cf155a24b1da15becaa390438d8", GitTreeState:"clean", BuildDate:"2020-03-25T14:58:59Z", GoVersion:"go1.13.8", Compiler:"gc", Platform:"darwin/amd64"}
Server Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.0", GitCommit:"9e991415386e4cf155a24b1da15becaa390438d8", GitTreeState:"clean", BuildDate:"2020-03-25T20:56:08Z", GoVersion:"go1.13.8", Compiler:"gc", Platform:"linux/amd64"}

cat <<EOL | kubectl apply -f-
apiVersion: v1
kind: Pod
metadata:
  name: node-hello
spec:
  containers:
  - name: node-hello
    image: docker.io/superbrothers/node-hello
EOL

kubectl exec node-hello -- ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.8  1.4 589724 29044 ?        Ssl  04:40   0:00 node index.js
root        13  0.0  0.1  36636  2724 ?        Rs   04:41   0:00 ps aux

kubectl delete po node-hello
```

`node index.js` コマンドが PID 1 で実行されていることがわかります。次に Shared Process Namespace を有効にして作成してみます。この機能は Pod `spec.shareProcessNamespace` を `true` にすることで有効になります。

```
cat <<EOL | kubectl apply -f-
apiVersion: v1
kind: Pod
metadata:
  name: node-hello
spec:
  shareProcessNamespace: true
  containers:
  - name: node-hello
    image: docker.io/superbrothers/node-hello
EOL

kubectl exec node-hello -- ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   1024     4 ?        Ss   04:44   0:00 /pause
root         8  0.3  1.4 589724 28968 ?        Ssl  04:44   0:00 node index.js
root        22  0.0  0.1  36636  2852 ?        Rs   04:45   0:00 ps aux
```

shareProcessNamespace を有効にした Pod は PID 1 に `/pause` というコマンドが実行されています。そのためアプリケーションコンテナのプロセスが PID 1 で実行されることを避けられることで、PID 1 問題を回避できます。この `/pause` がどこからやってきたのかというと、Kubernetes では Pod に含まれるコンテナを実行する際にゾンビプロセスの刈り取りとそれらコンテナの Network ネームスペースを共有するために pause というコンテナが必ず付いてくるようになっているのです。このコンテナのおかげで Pod に含まれるコンテナ同士は localhost で通信し合えるというわけです。

## まとめ

PID 1 問題の回避策は、アプリケーションが「明示的にシグナルをハンドリングするようにする」、または「PID 1 で実行されないようにする」の2つです。アプリケーションプロセスが PID 1 で実行されないようにする場合、Docker では Tini のような軽量 init を使う、もしくは Docker 1.13 以上の場合は `docker run` の `--init` オプションを使うで問題を回避できます。Kubernetes では Pod shareProcessNamespace を使うことで問題を回避できます。
