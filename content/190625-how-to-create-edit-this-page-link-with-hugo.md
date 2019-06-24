---
title: "Hugo で記事ページに「Edit this page（このページを編集する）リンク」をつくる"
date: 2019-06-24T23:35:20Z
draft: false
tags: ["hugo"]
---

## はじめに

ブログで投稿した記事のちょっとした typo を修正するために GitHub リポジトリから該当記事のマークダウンファイルにたどり着くまでがとても面倒だったのと、あわよくば記事に問題を見つけた人がプルリクエスト（PR）してくれるかもしれないので、それを目的に「Edit this page（このページを編集する）」という記事のソースファイルにワンクリックでたどり着けるリンクを各記事の下部に用意しました。

![Edit this page リンク](/images/190625-how-to-create-edit-this-page-link-with-hugo/edit-this-page.png)

少し前だったかに Microsoft のドキュメントで PR が送れる仕組みがあってよいみたいなので、話題になっていたアレです。ここでは、それを Huge で実現する方法を解説します。これはブログなのでわざわざ間違いを PR してくれる人は少ないと思いますが、プロダクトのドキュメントなどでは有用だと思います。

## 「Edit this page リンク」をつくる

今回「Edit this pageリンク」は、全ての記事ページに共通して追加する必要があります。Hugo テーマを利用している場合、リンクを追加したい場所に任意の HTML タグを追加できるような拡張性を備えているかどうかを確認する必要があります。現在このブログで利用させてもらっている [paper テーマ](https://themes.gohugo.io/hugo-paper/)は、記事ページのフッタ部分に任意のタグを追加できなかったため、`themes/paper/layouts/_default/single.html` に次のようなコードを追加しました。

```diff
diff --git a/themes/paper/layouts/_default/single.html b/themes/paper/layouts/_default/single.html
index 6d0935e..57c7b4e 100644
--- a/themes/paper/layouts/_default/single.html
+++ b/themes/paper/layouts/_default/single.html
@@ -17,6 +17,7 @@
       {{ end }}
     </ul>
     {{ end }}
+    {{ partial "post-footer-include.html" . }}
   </footer>
   <!-- Comments system area start -->
   {{ if not (eq .Params.comments false) }}
```

Hugo では、各記事のテンプレートファイルは `single.html` です。このファイルの任意のタグを挿入したい場所に `{{ partial "post-footer-include.html" . }}` というコードを挿入しています。これは、`post-footer-include.html` という部分テンプレート（Pertial Templates）が存在すればそれを挿入するというコードです。この変更で各記事のフッタ部分に任意のコードを挿入できるようになります。このようにどうしても Hugo テーマに手を加える必要がある場合、このように部分テンプレートを利用してテーマのコードへの変更を最小限（ここでは1行）にするようにすることで、テーマ自体のアップデートにもコンフリクトができる限り起きにくいようにしています（Hugo に明るくないためもしかしたらよりよい方法があるかもしれません）。

次に部分テンプレートを `layouts/pertials/post-footer-include.html` として作成します。

```html
<div class="post-footer-include">
    <a class="edit-this-page" href="https://github.com/superbrothers/text.superbrothers.dev/tree/master/content/{{$.Page.File.Path}}">Edit this page</a>
</div>
```

ここは、GitHub リポジトリの URL をベタ書きしています。見てわかるとおり、`superbrothers/text.superbrothers.dev` リポジトリの master ブランチを指しています。その後のパスで `{{$.Page.File.Path}}` を使っています。これは「現在の記事のファイルのパス」が格納されている変数です。例えばこのブログの https://text.superbrothers.dev/190622-how-to-stop-twitter-auto-linking-urls/ の `$.Page.File.Path` は、`190622-how-to-stop-twitter-auto-linking-urls.md` になります。結果として上の変更で挿入した「Edit this Page」リンクの遷移先 URL は、`https://github.com/superbrothers/text.superbrothers.dev/tree/master/content/190622-how-to-stop-twitter-auto-linking-urls.md` となり、記事ページから GitHub リポジトリ上のマークダウンファイルへのリンクになります。

もちろん、自身のブログやプロジェクトサイトで上記を実施する場合は、ベースとなる URL を自身のブログやプロジェクトサイトの GitHub リポジトリに合わせて変更してください。

## まとめ

今回は各記事ページに「Edit this page」リンクを追加して、小さな変更のしやすさ向上や PR がもらいやすいようにする方法を紹介しました。Hugo テーマを弄らないと行けない場合、テーマのコードを大きく変更してしまうとアップデートに追従するのが難しくなるので、部分テンプレートを使う方法も紹介しました。実際にこのブログにリンクを追加したコードは https://github.com/superbrothers/text.superbrothers.dev/commit/bcdabf5778ca9b5ab61341ceaa678b7e3fdf94ac から参照してください。

というわけで、この記事ページにもこの下に「Edit this page」リンクが見えるはずなので、もし何か間違えがあれば遠慮なく PR やイシューの作成をお願いします。
