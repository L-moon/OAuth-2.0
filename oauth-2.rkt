#lang racket
(require net/url net/uri-codec)
(require (planet dherman/json:3:0))
(require "oauth-object.rkt")
(require "utils/web-helper.rkt")

;;Very basic mechanism for OAuth 2.0 protocol.

(define encode form-urlencoded-encode)

(struct exn:fail:authorization exn:fail (type))


;;todo move this somewhere else
(define (insert-between lst v)
  (cond
    [(empty? lst) lst]
    [(empty? (rest lst)) lst]
    [else (cons (first lst)
                (cons v (insert-between (rest lst) v)))]))            

;;make-authorization-request : oauth-object string (listof string) -> string
(define (make-authorization-request oauth-obj
                                    #:state state
                                    #:scope scope)
  (define url (string->url (get-authorization-uri oauth-obj)))  
  (define response-type (get-response-type oauth-obj))
  (define (make-query)
    (list (cons 'client_id (get-client-id oauth-obj))                            
          (cons 'redirect_uri (get-redirect-uri oauth-obj))
          (cons 'response_type response-type)
          (cons 'scope (apply string-append (insert-between scope " ")))
          (cons 'state state)))
    
  (if response-type
      (begin 
        (set-url-query! url (make-query))
        url)
      (error 'make-authorization-request "grant-type should be either ~a or ~a"
             'authorization-code 'token)))

      

;;request-authorization-code : oauth-object string (listof string) (string -> any) -> any
(define (request-authorization-code oauth-obj
                                    #:state (state #f)
                                    #:scope (scope empty)
                                    #:request-method (req-method (lambda (v) v)))
  (define str-url (url->string
                   (make-authorization-request oauth-obj 
                                               #:state state
                                               #:scope scope)))
  (req-method str-url))

  
  
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

  
;;make-post-string : (listof (pairof symbol (or string #f))) -> string
(define (make-post-string loq)
  (define filtered-loq (filter (lambda (query) (cdr query)) loq))
  (define to-string (map (lambda (query) (string-append
                                          (symbol->string (car query))
                                          "="
                                          (encode (cdr query))))
                         filtered-loq))
  (apply string-append (insert-between to-string "&")))

;;grant-type : symbol -> string
(define (grant-type->string gt)
  (case gt
    [(authorization-code) "authorization_code"]
    [(password) "password"]
    [(client-cred) "client_credentials"]
    [(refresh-token) "refresh_token"]
    [else (error 'grant-type->string "invalid grant type ~a" gt)]))

;;make-common-query : oauth-object boolean -> (listof (pairof symbol string))
(define (make-common-query-list oauth-obj with-redirect?)
  (define common
    (list (cons 'client_id (get-client-id oauth-obj))
          (cons 'client_secret (get-client-secret oauth-obj))
          (cons 'grant_type (grant-type->string (get-grant-type oauth-obj)))))
  
    (if with-redirect?        
        (append common
                (list (cons 'redirect_uri (get-redirect-uri oauth-obj))))
        common))
         
   

;;make-post-type-auth-code : oauth-object string -> string 
(define (make-post-type-auth-code oauth-obj code)
  (make-post-string
   (append (make-common-query-list oauth-obj #t)
           (list (cons 'code code)))))
   
;;make-post-type-password : oauth-object (or string #f) (or string #f) (or string #f) -> string
(define (make-post-type-password oauth-obj username
                                           password
                                           scope)
  (make-post-string
   (append (make-common-query-list oauth-obj #f)
           (list (cons 'username username)
                 (cons 'password password)
                 (cons 'scope scope)))))

;;make-post-type-client : oauth-object (or string #f) -> string
(define (make-post-type-client oauth-obj scope)
  (make-post-string
   (append (make-common-query-list oauth-obj #f)
           (list (cons 'scope scope)))))

;;make-post-type-refresh : oauth-object (or string #f) (or string #f) -> string
(define (make-post-type-refresh oauth-obj refresh-token scope)
  (make-post-string
   (append (make-common-query-list oauth-obj #f)
           (list (cons 'refresh_token refresh-token)
                 (cons 'scope scope)))))

;;make-access-request : oauth-object (or string #f) (or string #f) (or string #f) (or string #f) (or string #f) -> string
(define (make-access-request oauth-obj code username password refresh-token scope)
  (define grant-type (get-grant-type oauth-obj))
  (define post-string
    (case grant-type
      [(authorization-code) (make-post-type-auth-code oauth-obj code)]
      [(password) (make-post-type-password oauth-obj username password scope)]
      [(client-cred) (make-post-type-client oauth-obj scope)]
      [(refresh-token) (make-post-type-refresh oauth-obj refresh-token scope)]
      [else (error 'make-access-request "unknown grant-type ~a" grant-type)]))
  
  post-string)

;;request-access-token: oauth-object (or string #f) (or string #f) (or string #f) (or string #f) (listof string) -> hash
(define (request-access-token oauth-obj
                              #:code (code #f)
                              #:username (username #f)
                              #:password (password #f)
                              #:refresh-token (refresh-token #f)
                              #:scope (scope empty))
  
  
  
  (define new-oauth-obj (if refresh-token 
                            (make-oauth-with-grant-type oauth-obj 'refresh-token)
                            oauth-obj))
  
  (define new-scope (if (empty? scope) #f (apply string-append (insert-between scope " "))))
  (define post-string (make-access-request new-oauth-obj code username password refresh-token new-scope))  
  (request-token new-oauth-obj post-string))

;;request-token: oauth-object string -> hash
(define (request-token oauth-obj post-string)
  (define extra-headers (list "Content-Type: application/x-www-form-urlencoded"))
  (define token-uri (get-token-uri oauth-obj))
  (call/input-url (string->url token-uri)
                  (lambda (url)
                    (post-impure-port url
                                      (string->bytes/utf-8 post-string)
                                      extra-headers))
                  (lambda (in)
                    (make-json-object (purify-port in) in))))
                    
  

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
    [else (raise
           (exn:fail:authorization
            (format "request-token-error: Cannot parse header: ~a \n content: ~a"
                    headers (port->bytes in)) 'request-access-token))]))
    
;     (error 'request-token "can't parse, header: ~a , content:~a " ;??
;                 headers (port->bytes in))]))  
  
(define (content-type str)
  (cond
    [(regexp-match? #rx"Content-Type.*json" str) 'json]
    [(regexp-match? #rx"text/plain" str) 'text-plain]
    [else #f]))
  

  

(provide make-oauth-2 oauth-object?
         request-authorization-code
         get-grant-resp 
         request-access-token
         (struct-out exn:fail:authorization))

         


  
  
  


                              
                                 
                                 