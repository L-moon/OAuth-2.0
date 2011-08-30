#lang racket
(require net/url net/uri-codec)
(require (planet dherman/json:3:0))
(require "oauth-object.rkt")
(require "utils/web-helper.rkt")

;;Very basic mechanism for OAuth 2.0 protocol.

(define encode form-urlencoded-encode)

;;todo move this somewhere else
(define (insert-between lst v)
  (cond
    [(empty? lst) lst]
    [(empty? (rest lst)) lst]
    [else (cons (first lst)
                (cons v (insert-between (rest lst) v)))]))            


;;request-owner-for-grant: oauth string (listof string) (string -> any) -> any
;;This is a first step in authorization process.
(define (request-owner-for-grant oauth-obj 
                                 #:state (state #f)
                                 #:scope (scope empty)
                                 #:redirect-proc 
                                 (redirect-proc (lambda (str-url) str-url)))
  
  (define url (string->url (get-authorization-uri oauth-obj)))  
  (define query (list (cons 'client_id (get-client-id oauth-obj))                            
                      (cons 'redirect_uri (get-redirect-uri oauth-obj))
                      (cons 'response_type (get-response-type oauth-obj))
                      (cons 'scope (apply string-append (insert-between scope " ")))
                      (cons 'state state)))
  (begin 
    (set-url-query! url query)
    (redirect-proc (url->string url))))
  
  
;;get-grant-resp: request -> (values string/false string/false string/false) 
;;May be second step.Returns three values :
;;1. code  : resource owner have granted access
;;2. state : the thing we initially passed to authorization server
;;3. error : resource owner failed to grant access , or some other error.
(define (get-grant-resp request)
  (define (get-code bindings)
    (if (binding-exists? 'code bindings)
        (get-value 'code bindings)
        #f))
    
  (define (get-state bindings)
    (if (binding-exists? 'state bindings)
        (get-value 'state bindings)
        #f))
      
  (define (get-error bindings)
    (if (binding-exists? 'error bindings)
        (get-value 'error bindings)
        #f))
  
  (let ([bindings (get-bindings request)])
    (values (get-code bindings)
            (get-state bindings)
            (get-error bindings))))

  

;;request-token : oauth string string -> hash or error
;;Third  step in authorization.Produces a json-object which is a hash which either contains
;;access-token or some kind of error.
(define (request-token oauth-obj #:code-or-token code-or-token 
                       #:grant-type (grant-type "authorization_code"))
  
  (define refresh?
    (string=? grant-type "refresh_token"))
  
  (define (http-ok? headers)
    (regexp-match? #rx"HTTP/.* 200 OK" headers))
      
  (define extra-headers (list "Content-Type: application/x-www-form-urlencoded"))
  
  (define post-string     
    (string-append
     "client_id=" (encode (get-client-id oauth-obj))  "&"
     "client_secret=" (encode (get-client-secret oauth-obj)) "&"       
     "grant_type=" grant-type "&"
     (if refresh?
         (string-append "refresh_token=" (encode code-or-token))
         (string-append 
          "redirect_uri=" (encode (get-redirect-uri oauth-obj)) "&"
          "code=" (encode code-or-token)))))
  
  (define token-uri (get-token-uri oauth-obj))
  (define in (post-impure-port (string->url token-uri) 
                               (string->bytes/utf-8 post-string) extra-headers))
  (define headers (purify-port in))
    
  (make-json-object headers in))
  

(define (make-json-object headers in)
  
  ;;as per spec the response should be in json format , but 
  ;;it seems that facebook does not follow it, therefore the hack.
  (define (text/plain->json-obj str)
    (define dummy-url (string->url
                       (string-append "http://www.example.com/?"
                                      str)))
    (make-hash (url-query dummy-url)))
  
  (case (content-type headers)
    [(json) (read-json in)] ;safe
    [(text-plain) (let ([str (port->string in)]) ; unsafe
                    (text/plain->json-obj str))]                               
    [else (error 'request-token "can't parse, header: ~a , content:~a " ;??
                 headers (port->bytes in))]))  
  
(define (content-type str)
  (cond
    [(regexp-match? #rx"Content-Type.*json" str) 'json]
    [(regexp-match? #rx"text/plain" str) 'text-plain]
    [else #f]))
  

;;request-access-token : oauth string -> hash or error
(define (request-access-token oauth-obj #:code code)
  (request-token oauth-obj #:code-or-token code ))

;;Not tested
;;refresh-access-token : oauth string -> hash or error
(define (refresh-access-token oauth-obj #:refresh-token refresh-token)
  (request-token oauth-obj #:code-or-token refresh-token 
                 #:grant-type "refresh_token"))

(provide make-oauth-2
         request-owner-for-grant
         get-grant-resp 
         request-access-token
         refresh-access-token)



  
  
  


                              
                                 
                                 