;; -*- coding: utf-8 -*-

(use gauche.test)
(use srfi-1)

(test-start "html2text.scm")

(test-section "モジュールのテスト")

(use html2text)
(test-module 'html2text)

(test-section "段落のテスト")

(test* "段落を抽出すること。" "テスト" (html2text "http://example.com" "<p>テスト</p>"))
(test* "空白を削除すること。" "テスト1\n\nテスト2" (html2text "http://example.com" "<div>
  <p>テスト1</p>
  <p>テスト2</p>
</div>"))
(test* "属性つきの段落を抽出すること。" "テスト" (html2text "http://example.com" "<p foo=\"bar\">テスト</p>"))
(test* "<head>タグを無視すること。" "テスト" (html2text "http://example.com" "<html><head><title>タイトル</title></head><body><p>テスト</p></body></html>"))
(test* "<script>タグを無視すること。" "テスト" (html2text "http://example.com" "<html><body><p><script language=\"JavaScript\">alert(\"ERROR!\");</script>テスト</p></body></html>"))

(test-section "リストのテスト")

(test* "<ul>タグ内をリスト表示すること。" "* テスト" (html2text "http://example.com" "<html><body><p><ul><li>テスト</li></ul></p></body></html>"))
(test* "<ul>タグ内の複数の<li>タグをリスト表示すること。" "* foo\n\n* bar" (html2text "http://example.com" "<html><body><p><ul><li>foo</li><li>bar</li></ul></p></body></html>"))

(test* "<ol>タグ内をリスト表示すること。" "1. テスト" (html2text "http://example.com" "<html><body><p><ol><li>テスト</li></ol></p></body></html>"))
(test* "<ol>タグ内を番号つきでリスト表示すること。" "1. foo\n\n2. bar" (html2text "http://example.com" "<html><body><p><ol><li>foo</li><li>bar</li></ol></p></body></html>"))

(test* "<ul>タグをネストして表示すること。" "* foo\n\n  * bar" (html2text "http://example.com" "<html><body><ul><li>foo</li><ul><li>bar</li></ul></ul></body></html>"))
(test* "<ul>タグをネストして表示すること（内部のリストが複数の項目を持つ）。" "* foo\n\n  * bar\n\n  * baz" (html2text "http://example.com" "<html><body><ul><li>foo</li><ul><li>bar</li><li>baz</li></ul></ul></body></html>"))
(test* "<ul>タグをネストして表示すること（ネストが元に戻る）。" "* foo\n\n  * bar\n\n* baz" (html2text "http://example.com" "<html><body><ul><li>foo</li><ul><li>bar</li></ul><li>baz</li></ul></body></html>"))

(test* "<ol>タグをネストして表示すること。" "1. foo\n\n  1. bar" (html2text "http://example.com" "<html><body><ol><li>foo</li><ol><li>bar</li></ol></ol></body></html>"))
(test* "<ol>タグをネストして表示すること（内部のリストが複数の項目を持つ）。" "1. foo\n\n  1. bar\n\n  2. baz" (html2text "http://example.com" "<html><body><ol><li>foo</li><ol><li>bar</li><li>baz</li></ol></ol></body></html>"))
(test* "<ol>タグをネストして表示すること（ネストが元に戻る）。" "1. foo\n\n  1. bar\n\n2. baz" (html2text "http://example.com" "<html><body><ol><li>foo</li><ol><li>bar</li></ol><li>baz</li></ol></body></html>"))

(test-section "アンカーのテスト")

(test* "アンカーを最後に表示すること。" "[foo][1]\n\n[1]（foo）: http://example.com/" (html2text "http://example.com" "<html><body><p><a href=\"http://example.com/\">foo</a></p></body></html>"))
(test* "アンカーを順番に表示すること。" "[foo][1][bar][2]\n\n[1]（foo）: http://example.com/foo/\n[2]（bar）: http://example.com/bar/" (html2text "http://example.com" "<html><body><p><a href=\"http://example.com/foo/\">foo</a><a href=\"http://example.com/bar/\">bar</a></p></body></html>"))
(test* "番号つきリスト内のアンカーを表示すること。" "1. [foo][1]\n\n[1]（foo）: http://example.com/" (html2text "http://example.com" "<html><body><p><ol><li><a href=\"http://example.com/\">foo</a></li></ol></p></body></html>"))
(test* "リスト内のアンカーを表示すること。" "* [foo][1]\n\n[1]（foo）: http://example.com/" (html2text "http://example.com" "<html><body><p><ul><li><a href=\"http://example.com/\">foo</a></li></ul></p></body></html>"))
(test* "相対パスのアンカーを表示すること。" "[foo][1]\n\n[1]（foo）: http://example.com/foo" (html2text "http://example.com/" "<html><body><p><a href=\"foo\">foo</a></p></body></html>"))
(test* "絶対パスのアンカーを表示すること。" "[foo][1]\n\n[1]（foo）: http://example.com/foo" (html2text "http://example.com/bar" "<html><body><p><a href=\"/foo\">foo</a></p></body></html>"))

(test-section "画像のテスト")

(test* "画像のURLを表示すること。" "[foo.png][1]\n\n[1]（foo.png）: http://example.com/foo.png" (html2text "http://example.com" "<html><body><p><img src=\"http://example.com/foo.png\"></p></body></html>"))
(test* "画像の代替文字を表示すること。" "[bar][1]\n\n[1]（bar）: http://example.com/foo.png" (html2text "http://example.com" "<html><body><p><img alt=\"bar\" src=\"http://example.com/foo.png\"></p></body></html>"))
(test* "アンカーになっている画像を表示すること。" "[[foo.png][2]][1]\n\n[1]（[foo.png][2]）: http://example.com/bar\n[2]（foo.png）: http://example.com/foo.png" (html2text "http://example.com" "<html><body><p><a href=\"http://example.com/bar\"><img src=\"http://example.com/foo.png\"></a></p></body></html>"))
(test* "相対パスの画像のURLを表示すること。" "[foo.png][1]\n\n[1]（foo.png）: http://example.com/foo.png" (html2text "http://example.com/" "<html><body><p><img src=\"foo.png\"></p></body></html>"))
(test* "絶対パスの画像のURLを表示すること。" "[foo.png][1]\n\n[1]（foo.png）: http://example.com/foo.png" (html2text "http://example.com/bar.png" "<html><body><p><img src=\"/foo.png\"></p></body></html>"))

(test-section "<pre>のテスト")

(test* "<pre>の内容をそのまま表示すること。" "foo\nbar\nbaz" (html2text "http://example.com" "<pre>foo\nbar\nbaz</pre>"))
(test* "<pre>内のタグを無視すること。" "foo\nbar\nbaz" (html2text "http://example.com" "<pre><span>foo</span>\nbar\nbaz</pre>"))

(test-section "実体参照のテスト")

(test* "&nbsp;を空白一つに変換すること。" "foo bar" (html2text "http://example.com/" "foo&nbsp;bar"))
(test* "&times;をXに変換すること。" "X" (html2text "http://example.com/" "&times;"))

(test-section "コメントのテスト")

(test* "コメントを出力しないこと。" "" (html2text "http://example.com/" "<!-- ERROR -->"))

(test-section "見出しのテスト")

(let1 test-h (lambda (proc) (for-each (cut proc <>) (iota 6)))
  (test-h
    (lambda (n)
      (let1 level (+ n 1)
        (test* 
          (format #f "<h~a>を出力すること。" level) 
          (format #f "~a テスト" (make-string level #\*)) 
          (html2text 
            "http://example.com/" 
            (format 
              #f "<html><body><h~a>テスト</h~a></body></html>" level level))))))

  (test-h
    (lambda (n)
      (let1 level (+ n 1)
        (test* 
          (format #f "段落後の<h~a>を出力すること。" level) 
          (format #f "段落\n\n~a テスト" (make-string level #\*)) 
          (html2text 
            "http://example.com/" 
            (format 
              #f 
              "<html><body><p>段落</p><h~a>テスト</h~a></body></html>" 
              level 
              level)))))))

(test* "DOCTYPEを持つHTMLを処理すること。" "テスト" (html2text "http://example.com/" "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">
<html>
<body>
<p>テスト</p>
</body>
</html>"))

(test-end)

;; vim: tabstop=2 shiftwidth=2 expandtab softtabstop=2 filetype=scheme
