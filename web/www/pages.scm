;;; Copyright © 2016, 2017  Roel Janssen <roel@gnu.org>
;;;
;;; This program is free software: you can redistribute it and/or
;;; modify it under the terms of the GNU Affero General Public License
;;; as published by the Free Software Foundation, either version 3 of
;;; the License, or (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with this program.  If not, see
;;; <http://www.gnu.org/licenses/>.

(define-module (www pages)
  #:use-module (srfi srfi-1)
  #:use-module (www config)
  #:export (page-root-template))

(define page-title-prefix (string-append %www-name " | "))

(define pages
  '(("/" "Overview")
    ("/query" "Query")
    ("/load-data" "Load data")
    ("/getting-started" "Getting started")
    ("/about" "About")
    ("/ontologies" "Ontologies")
    ("/help" "Help")))

(define (page-partial-main-menu request-path)
  `(ul
    ,(map
      (lambda (item)
        (cond
         ((string= (substring (car item) 1) (car (string-split (substring request-path 1) #\/)))
          `(li (@ (class "active")) ,(cadr item)))
         ((and (string= "query" (car (string-split (substring request-path 1) #\/)))
               (string= (car item) "/query"))
          `(li (@ (class "active")) (a (@ (href "/query")) "← New query")))
         ((and (string= "cth" (car (string-split (substring request-path 1) #\/)))
               (string= (car item) "/query"))
          `(li (@ (class "active")) (a (@ (href "/query")
                     (onclick "history.go(-1); return false;")) "← Go back")))
         (else
          `(li (a (@ (href ,(car item))) ,(cadr item))))))
      pages)))

(define* (page-root-template title request-path content-tree #:key (dependencies '(test)))
  `((html (@ (lang "en"))
     (head
      (title ,(string-append page-title-prefix title))
      (meta (@ (http-equiv "Content-Type") (content "text/html; charset=utf-8")))
      (link (@ (rel "icon")
               (type "image/x-icon")
               (href "/static/favicon.ico")))
      ,(if (memq 'highlight dependencies)
         `((link (@ (rel "stylesheet") (href "/static/highlight/styles/github.css")))
           (script (@ (src "/static/highlight/highlight.pack.js")) "")
           (script "hljs.initHighlightingOnLoad();"))
         `())
      ,(if (memq 'jquery dependencies)
           `(script (@ (type "text/javascript") (src "/static/jquery-3.2.1.min.js")) "")
           `())
      ,(if (memq 'datatables dependencies)
           `((link (@ (rel "stylesheet") (type "text/css") (href "/static/datatables.min.css")))
             (script (@ (type "text/javascript") (src "/static/jquery.dataTables.min.js")) ""))
           `())
      ,(if (memq 'ace dependencies)
           `(script (@ (type "text/javascript") (charset "utf-8") (src "/static/ace/ace.js")) "")
           `())
      (link (@ (rel "stylesheet")
               (href "/static/css/main.css")
               (type "text/css")
               (media "screen"))))
     (body
      (div (@ (id "wrapper"))
           (div (@ (id "header"))
                (div (@ (class "title"))
                     (h1 ,%www-name))
                (div (@ (class "menu"))
                     ,(page-partial-main-menu request-path)))
           (div (@ (id "content"))
                ,content-tree)
           (div (@ (id "footer")) ""))))))
