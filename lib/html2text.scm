;; -*- coding: utf-8 -*-

(define-module html2text 
  (export html2text)
  (use file.util)
  (use gauche.interactive)
  (use rfc.uri)
  (use srfi-13)
  (use util.match)
  (use html2text.htmlprag))
(select-module html2text)

(define-class <link> () (
    (url :init-keyword :url :init-value "")
    (text :init-keyword :text :init-value "")))

(define-class <parser-status> () (
    (empty :init-keyword :empty :init-value #t)
    (links :init-keyword :links :init-form '())
    (index :init-keyword :index :init-form '())
    (tag-stack :init-keyword :tag-stack :init-form '())
    (indent :init-keyword :indent :init-value -1)))

(define (output-string s status port)
  (display s port)
  (set! (ref status 'empty) (and (ref status 'empty) (string=? s ""))))

(define (output-unless-empty s status port)
  (output-string (if (ref status 'empty) "" s) status port))

(define (output-vspace status port) (output-unless-empty "\n\n" status port))

(define (h2t url html status port)
  (define (update-indent f)
    (set! (ref status 'indent) (f (ref status 'indent) 1)))

  (define (decrement-indent) (update-indent -))

  (define (increment-indent) (update-indent +))

  (define (make-indent n) (make-string (* n 2) #\space))

  (define (output-html port) (for-each (cut h2t url <> status port) (cdr html)))

  (define (output-indented-html port) 
    (increment-indent) (output-html port) (decrement-indent))

  (define (find-tag status tags)
    (let loop ((tag #f) (tag-stack (ref status 'tag-stack)))
      (if (pair? tag-stack)
        (let ((top-tag (car tag-stack)))
          (loop 
              (if (find (cut equal? <> top-tag) tags) top-tag tag) 
              (cdr tag-stack)))
        tag)))

  (define (find-list-tag status) (find-tag status '(ol ul)))

  (define (find-pre-tag status) (find-tag status '(pre)))

  (define (join-url url path)
    (if (#/^[a-z]+:\/\// path)
      path
      (receive 
          (scheme userinfo host port url-path query fragment) (uri-parse url)
        (uri-compose 
          :scheme scheme 
          :userinfo userinfo 
          :host host
          :port port 
          :path 
            (if (string-prefix? "/" path) 
              path 
              (simplify-path 
                (string-join (list (if url-path url-path "") path) "/")))
          :query #f
          :fragment #f))))

  (if (pair? html)
    (let ((tag (car html)))
      (define (append-link! status)
        (set!  (ref status 'links) (cons (make <link>) (ref status 'links))))

      (set! (ref status 'tag-stack) (cons tag (ref status 'tag-stack)))
      (case tag
        ((&) 
          (display 
            (case (cadr html)
              ((nbsp) " ")
              ((times) "X"))
            port))
        ((head script *COMMENT* *DECL*))
        ((a) 
          (append-link! status) 
          (let (
              (aport (open-output-string)) 
              (link (car (ref status 'links)))
              (link-id (length (ref status 'links))))
            (output-html aport)
            (let ((text (get-output-string aport)))
              (set! (ref link 'text) text)
              (output-string (format #f "[~a][~a]" text link-id) status port))))
        ((br) (output-string "\n" status port))
        ((img) 
          (append-link! status) 
          (output-html port)
          (let* ((links (ref status 'links)) (link (car links)))
            (output-string 
                (format #f "[~a][~a]" (ref link 'text) (length links)) 
                status 
                port)))
        ((ol ul)
          (set! (ref status 'index) (cons -1 (ref status 'index)))
          (output-indented-html port)
          (set! (ref status 'index) (cdr (ref status 'index))))
        ((li)
          (output-vspace status port)
          (let ((index (ref status 'index)))
            (set! (ref status 'index) (cons (+ (car index) 1) (cdr index))))
          (output-string 
              (format 
                  #f 
                  "~a~a " 
                  (make-indent (ref status 'indent)) 
                  (case (find-list-tag status)
                    ((ol) (format #f "~a." (+ (car (ref status 'index)) 1)))
                    ((ul) "*")
                    (else (error "Can't find <ol> or <ul>."))))
              status 
              port)
          (output-html port))
        ((p)
          (output-vspace status port)
          (output-html port))
        ((h1 h2 h3 h4 h5 h6)
          (output-vspace status port)
          (output-string 
            (format 
              #f 
              "~a " 
              (make-string 
                (digit->integer (string-ref (symbol->string tag) 1)) #\*))
            status 
            port)
          (output-html port))
        (else (output-html port)))
      (set! (ref status 'tag-stack) (cdr (ref status 'tag-stack))))
    (let* ((tag-stack (ref status 'tag-stack)))
      (define (set-link-attr! status attr html)
        (let* ((links (ref status 'links)) (link (car links)))
          (set! (ref link attr) html)))

      (define (set-link-url! status html) (set-link-attr! status 'url html))

      (define (set-link-text! status html) (set-link-attr! status 'text html))

      (match tag-stack
        (('href '@ 'a . _) (set-link-url! status (join-url url html)))
        (('src '@ 'img . _) 
          (set-link-url! status (join-url url html))
          (let* ((links (ref status 'links)) (link (car links)))
            (if (string=? (ref link 'text) "")
              (set-link-text! status (sys-basename html))
              #t)))
        (('alt '@ 'img . _) (set-link-text! status html))
        ((_ '@ . _) #f)
        (else 
          (output-string 
              (if (find-pre-tag status) html (string-trim-both html)) 
              status 
              port))))))

(define (output-links status port)
  (define (output-link n links port)
    (if (pair? links)
      (begin
        (let ((link (car links)))
          (display 
              (format #f "\n[~a]（~a）: ~a" 
                  (+ n 1) (ref link 'text) (ref link 'url)) 
              port))
        (output-link (+ n 1) (cdr links) port))
      #t))

  (let ((links (ref status 'links)))
    (if (< 0 (length links))
      (begin
        (output-unless-empty "\n" status port)
        (output-link 0 (reverse links) port))
      #t)))

(define (html2text url html)
  (let ((port (open-output-string)) (status (make <parser-status>)))
    (h2t url (html->sxml (open-input-string html)) status port)
    (output-links status port)
    (get-output-string port)))

(provide "html2text")

;; vim: tabstop=2 shiftwidth=2 expandtab softtabstop=2 filetype=scheme
