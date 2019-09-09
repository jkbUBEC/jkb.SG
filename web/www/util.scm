;;; Copyright © 2016, 2017, 2018, 2019  Roel Janssen <roel@gnu.org>
;;; Copyright © 2016  Ricardo Wurmus <rekado@elephly.net>
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

(define-module (www util)
  #:use-module (rnrs bytevectors)
  #:use-module (ice-9 binary-ports)
  #:use-module (ice-9 format)
  #:use-module (ice-9 match)
  #:use-module (ice-9 popen)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)
  #:use-module (sparql driver)
  #:use-module (srfi srfi-1)
  #:use-module (web response)
  #:use-module (web uri)
  #:use-module (www config)
  #:use-module (www db api)
  #:export (file-extension
            predicate-label
            string-replace-occurrence
            suffix-iri
            string-is-longer-than
            post-data->alist
            alist-symbol-key<?
            mkdir-p
            string->sha256sum
            generate-id
            is-uri?
            respond-to-client
            respond-200
            respond-200-with-cookie
            respond-201
            respond-204
            respond-303
            respond-401
            respond-403
            respond-404
            respond-405
            respond-406
            respond-500))

(define (string-is-longer-than str length)
  (catch 'out-of-range
    (lambda _ (if (string-ref str length) #t))
    (lambda (key . args) #f)))

(define (file-extension file-name)
  (last (string-split file-name #\.)))

(define (string-replace-occurrence str occurrence alternative)
  "Replaces every OCCURRENCE in STR with ALTERNATIVE."
  (string-map (lambda (x) (if (eq? x occurrence) alternative x)) str))

(define (suffix-iri input)
  (if input
      (string-trim-both
       (string-drop input
                    (1+ (string-rindex input #\/))) #\")
      "unknown"))

(define (predicate-label pred)
  "Returns the rdf:label of PRED, or PRED if rdf:label is unavailable."
  (catch 'system-error
    (lambda _
      (receive (header port)
          (sparql-query
           (format #f "PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
SELECT ?label { <~a> rdf:label ?label } LIMIT 1" (string-trim-both pred #\"))
                        #:type "text/csv")
        (if (= (response-code header) 200)
            (begin
              ;; The first line is the header.
              (read-line port)
              (let ((line (read-line port)))
                (if (or (eof-object? line)
                        (string= line ""))
                    pred
                    (string-trim-both line #\"))))
            pred)))
    (lambda (key . args) pred)))

(define (post-data->alist post-data)
  (catch #t
    (lambda _
      (map (lambda (item)
             (let ((pair (string-split item #\=)))
               `(,(string->symbol (uri-decode (car pair))) . ,(uri-decode (cadr pair)))))
           (sort (string-split post-data #\&) string<?)))
    (lambda (key . args) '())))

(define (alist-symbol-key<? a b)
          (string<? (symbol->string (car a))
                    (symbol->string (car b))))

(define (mkdir-p dir)
  "Create directory DIR and all its ancestors."
  (define absolute?
    (string-prefix? "/" dir))

  (define not-slash
    (char-set-complement (char-set #\/)))

  (let loop ((components (string-tokenize dir not-slash))
             (root       (if absolute?
                             ""
                             ".")))
    (match components
      ((head tail ...)
       (let ((path (string-append root "/" head)))
         (catch 'system-error
           (lambda ()
             (mkdir path)
             (loop tail path))
           (lambda args
             (if (= EEXIST (system-error-errno args))
                 (loop tail path)
                 (apply throw args))))))
      (() #t))))

(define (string->sha256sum input)
  (let* [(command (format #f "printf ~s | sha256sum" input))
         (port    (open-pipe command OPEN_READ))
         (result  (read-delimited " " port))]
    (close-pipe port)
    result))

(define (generate-id . arguments)
  (string->sha256sum (format #f "~{~a~}" arguments)))

(define (is-uri? string)
  (catch #t
    (lambda _
      (or (string-prefix? "http://" string)
          (string-prefix? "https://" string)
          (and (string-prefix? "<" string )
               (string-suffix? ">" string))))
    (lambda (key . args)
      #f)))

(define (respond-to-client response-code client-port content-type body)
  (set-port-encoding! client-port "utf8")
  (let [(content (string->utf8 body))]
    (write-response
     (build-response
      #:code response-code
      #:headers `((content-type   . ,content-type)
                  (content-length . ,(bytevector-length content))))
     client-port)
    (put-bytevector client-port content)))

(define (respond-with-error-message code client-port accept-type message)
  (let [(response-type (first-acceptable-format accept-type))]
    (if response-type
        (respond-to-client code client-port response-type
          (api-format response-type `(error (message ,message))))
        (respond-406 client-port))))

(define (respond-200 client-port accept-type data)
  (let [(response-type (first-acceptable-format accept-type))]
    (if response-type
        (respond-to-client 200 client-port response-type
          (api-format response-type data))
        (respond-406 client-port))))

(define (respond-200-with-cookie client-port cookie)
  (write-response
   (build-response
    #:code 200
    #:headers `((Set-Cookie . ,cookie)))
   client-port))

(define (respond-201 client-port)
  (write-response (build-response #:code 201) client-port))

(define (respond-204 client-port)
  (write-response (build-response #:code 204) client-port))

(define (respond-303 client-port location cookie)
  (write-response
   (if cookie
       (build-response
        #:code 303
        #:headers `((Location   . ,location)
                    (Set-Cookie . ,cookie)))
       (build-response
        #:code 303
        #:headers `((Location   . ,location))))
   client-port))

(define (respond-401 client-port accept-type message)
  (respond-with-error-message 401 client-port accept-type message))

(define (respond-403 client-port accept-type message)
  (respond-with-error-message 403 client-port accept-type message))

(define (respond-404 client-port accept-type message)
  (respond-with-error-message 404 client-port accept-type message))

(define (respond-405 client-port allowed-methods)
  (write-response
   (build-response #:code 405 #:headers `((Allow . ,allowed-methods)))
   client-port))

(define (respond-406 client-port)
  (respond-to-client 406 client-port '(text/plain)
    (format #f "No acceptable format.~%")))

(define (respond-500 client-port accept-type message)
  (respond-with-error-message 500 client-port accept-type message))
