---
title: "ロボットアカウントから GitHub Container Registry（GHCR）を使う"
date: 2020-11-02T10:54:44+09:00
tags: ["github", "github actions", "github container registry", "ghcr", "docker", "container"]
draft: false
images: ["/ogp/201102-using-github-container-registry-with-robot-account.png"]
---

## はじめに

Docker Hub の Rate Limit の件もあり、新しくイメージをホストするコンテナレジストリとして GitHub Container Registry（GHCR）を使ってみようとしましたが、ロボットアカウントから使用するのにいくつかハマりポイントがあったので残します。

## なぜロボットアカウントを使うのか

ロボットアカウントとは、ここでは開発者アカウントに紐付かず一般に特定の用途、例えばここではコンテナイメージのアップロード（プッシュ）のみに使用するアカウントのことを指します。GitHub には「ロボットアカウント」機能は存在しないので、一般のアカウントを作成しロボットアカウントとして使用することになります。

なぜ GHCR をロボットアカウントから使用する必要があるかというと、それは GHCR が GitHub Actions ワークフローの `GITHUB_TOKEN` のトークンではイメージをアップロードできないためです。

> Add your new container registry authentication personal access token (PAT) as a GitHub Actions secret. GitHub Container Registry does not support using `GITHUB_TOKEN` for your PAT so you must use a different custom variable, such as `CR_PAT`.

- [Migrating to GitHub Container Registry for Docker images \- GitHub Docs](https://docs.github.com/en/free-pro-team@latest/packages/getting-started-with-github-container-registry/migrating-to-github-container-registry-for-docker-images#updating-your-github-actions-workflow)

そのため、上記にあるとおりにパーソナルアクセストークン（PAT）を用意しないといけないのですが、個人リポジトリなら個人で払い出したトークンでよいのですが、チームや他の人とともに管理しているリポジトリだと個人のトークンは使用したくありません。そこで、新たにロボットアカウントとしてアカウントを作成して、そのアカウントでトークンを払い出して使おうということです。

ロボットアカウントの管理は面倒なのでやりたくありませんが、個人のトークンが使われるよりはマシです。

*個人の見解: `GITHUB_TOKEN` でイメージをアップロードできないのは、GHCR が Org レベルで存在しているためだと思っています。GitHub Actions ワークフローの `GITHUB_TOKEN` はそのリポジトリを操作できる権限を持つトークンなので、Org レベルで場所が用意されている GHCR はそのトークンでは操作させられないはずです。GHCR はリポジトリごとに場所が作られる仕様でよかったんじゃないかなと思わなくもないです。*

## 1. ロボットアカウントを Org に参加させる

ロボットアカウントを作成したら次にそのアカウントを Org のメンバとして参加させます。ここで外部のコラボレータ（Outside collaborator）として Org 内の特定のリポジトリに参加させてもイメージをアップロードできないことに注意してください。

メンバへの追加は `https://github.com/orgs/{org}/people` の「Invite member」ボタンから行えます。

![Invite member ボタン](https://lh3.googleusercontent.com/pw/ACtC-3de0hprTZKfSfjOaLuMXA2BB2cwywwfcJIYBXywOJWNLI9lpdiaWjvA6Cq3tQeNfu5zbs3FRVTGIzZUxgMsphME8LL04AiCIBn_O-7KCchaLPPxE_dYMmU4WVwwNHRz22Ci-5djigEVZz8Afo9IO8FewQ=w1740-h302-no)

## 2. メンバの「パッケージ作成」を許可する

Org のメンバはデフォルトだとパッケージ、ここではコンテナイメージのアップロードができません。`https://github.com/organizations/{org}/settings/member_privileges` の「Package creation」でイメージのアップロードを許可します。ここでは "Public" または "Private" どちらでアップロードできるかを選択できます。ここでは "Public" にします。

![Package creation でパッケージの作成を許可](https://lh3.googleusercontent.com/pw/ACtC-3eUHTW5nzqgYpdoLXK-HEQj42xJ-8F8cDahelLAEBAGq5PLLnHJYGeW_2-Vd5DhrX-y15MRQsQ83YRurVIqEHeCf8aDcpELeV00ppwkuzACIQ2Xpc1YWqLe6XnB7nz27dFqqx0-p3rB-Vdq2ppz155_QA=w1544-h502-no)

## 3. ロボットアカウントのパーソナルアクセストークンを作成

ロボットアカウントでパーソナルアクセストークンを作成します。ロボットアカウントで GitHub にアクセスした状態で https://github.com/settings/tokens/new にアクセスします。ここでトークンのスコープには `write:packages` を選択します。

![write:packages のスコープでトークンを作成](https://lh3.googleusercontent.com/pw/ACtC-3dVg5q75tFVCjrlIXylvdKuNvJ0U34uLNQKC1fDcXrIEMsHUxwdVoH9e-cG5KvNt5ah7lnAZ7784i0IoAjjcqVsA0oE2QkqEegofCMJIB9nQQlz61G0fTJiPbvJpyG7FSmZltM5JT-dXkEXKBNM64Y2VA=w1594-h890-no)

作成されたトークンはメモしておきます。

## 4. Organization secrets としてトークンを登録

GitHub Actions でトークンを参照するために Organization secrets としてトークンを登録します。Org secrets の登録は https://github.com/organizations/{org}/settings/secrets からできます。Secret 名は GHCR のドキュメントに従って `CR_PAT` なりにします。

![PAT を Org secrets として登録](https://lh3.googleusercontent.com/pw/ACtC-3fzbxE7WUJOtW8-Alic_ahe53QHBibCZBAHgWkN_9IrT2mZcw8pz2URDY4ghz8A1R9O7CvOK5kJiH_dgFEWC85C4xq80vyTnyV4f0VYv96qFssvCZT6kYSUdhapYu7JqkT5raY-Pmeg-H9-27Zoc5o8Zw=w1620-h784-no)

特定リポジトリの Secrets として保存するのでも問題ないのですが、トークン自体は Org レベルで有効なため、Org secrets として作成し、リポジトリに不要にトークンを払い出すのを避けたほうがよいかなと思います。

これで GitHub Actions ワークフローから `${{ secrets.CR_PAT }}` でトークンを参照できます。

## 5. GitHub Actions ワークフローの定義

さいごに GitHub Actions でイメージをビルドしアップロードするサンプルのワークフローを示します。

```yaml
name: Release

on:
  push:
    tags: ["v*"]

jobs:
  run:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Login to GitHub Container Registry
      run: echo "$CR_PAT" | docker login ghcr.io --username "$GITHUB_ACTOR" --password-stdin
      env:
        CR_PAT: ${{ secrets.CR_PAT }}
    - name: Build image
      run: docker build ghcr.io/my_org/my_app:${{ github.event.inputs.tag }} .
    - name: Push image to GitHub Container Registry
      run: docker push ghcr.io/my_org/my_app:${{ github.event.inputs.tag }}
```

## ほかのコンテナレジストリの選択肢は

パブリックで使用できる他の選択肢として Red Hat 社が運営する [Quay.io](https://quay.io/) があります。こちらにはロボットアカウント機能があります。

## さいごに

GHCR の基本的な使用については下記を参照ください。

- [Getting started with GitHub Container Registry \- GitHub Docs](https://docs.github.com/en/free-pro-team@latest/packages/getting-started-with-github-container-registry)
