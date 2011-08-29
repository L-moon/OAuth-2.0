#lang racket
(require web-server/http)

(define (gen-full-resp str)
  (response/full
   200 #"Okay"
   (current-seconds) TEXT/HTML-MIME-TYPE
   empty
   (list (string->bytes/utf-8 str))))

(define (get-bindings request)
  (let ([bindings (request-bindings/raw request)])
    bindings))
    
(define (get-value/file sym bindings)
  (let ([id (string->bytes/utf-8 (symbol->string sym))])
    (let ([bind (bindings-assq id bindings)])
      (if (binding:file? bind)
          (values (binding:file-filename bind) (binding:file-content bind))
          (error 'get-value/file "Not a file binding ~a" sym)))))
    
(define (get-value sym bindings)
  (let ([id (string->bytes/utf-8 (symbol->string sym))])
    (let ([bind (bindings-assq id bindings)])
      (let ([val (binding:form-value bind)])
        (bytes->string/utf-8 val)))))

(define (get-value/byte sym bindings)
  (let ([id (string->bytes/utf-8 (symbol->string sym))])
    (let ([bind (bindings-assq id bindings)])
      (let ([val (binding:form-value bind)])
        val))))

  

(define (binding-exists? sym bindings)
  (let ([id (string->bytes/utf-8 (symbol->string sym))])
    (let ([bind (bindings-assq id bindings)])
      bind)))

(provide (all-defined-out))

