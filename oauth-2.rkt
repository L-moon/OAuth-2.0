#lang racket
(require net/url net/uri-codec)
(require (planet dherman/json:3:0))
(require "utils/web-helper.rkt")

;;Very basic mechanism for OAuth 2.0 protocol.

;;Basic client credentials structure
(struct client-cred (client-id client-secret)) ;where
;;client-id is a string and
;;client-secret is a string

;;OAuth end-points
(struct end-points (authorization-uri token-uri))
;;A authorization-uri is a string from where , we ask
;;the resource owner to grant access.

;;A token-uri is a string from where , we authenticate 
;;ourself to get the access token , by passing it the
;;grant code from owner to it.


;;A response-type is either
;;1. code , or
;;2. token
;(struct response-type (resp-type))

;;A redirection-uri is a absolute uri

;;A basic oauth structure
(struct oauth (cc end-points redirect-uri response-type) #:transparent) ; where
;;cc is client-cred structure
;;redirect-uri is a string representation of a url
;;response-type is a string

;;make-outh : client-cred end-points string symbol -> oauth
;;produces a instance of oauth structure
;(define (make-oauth #:client-credentials client-cred
;                    #:oauth-endpoints end-points
;                    #:redirect-uri redirect-uri
;                    #:response-type (response-type 'code))
;  (oauth client-cred end-points redirect-uri (symbol->string response-type)))


;;produces oauth object
(define (make-oauth-2 #:client-id client-id
                      #:client-secret client-secret
                      #:authorization-uri authorization-uri
                      #:token-uri token-uri
                      #:redirect-uri redirect-uri
                      #:response-type (response-type 'code))
  ;;may be check for type?
  (oauth (client-cred client-id client-secret)
         (end-points authorization-uri token-uri)
         redirect-uri
         (symbol->string response-type)))




;;todo move this somewhere else
(define (insert-between lst v)
  (cond
    [(empty? lst) lst]
    [(empty? (rest lst)) lst]
    [else (cons (first lst)
                (cons v (insert-between (rest lst) v)))]))            


;;request-owner-for-grant: oauth string (listof string) (string -> any)
;;This is a first step in authorization process.
(define (request-owner-for-grant oauth-obj 
                                 #:state (state #f)
                                 #:scope (scope empty)
                                 #:redirect-proc 
                                 (redirect-proc (lambda (str-url) str-url)))
  (define client-cred (oauth-cc oauth-obj))
  (define end-points (oauth-end-points oauth-obj))
  (define redirect-uri (oauth-redirect-uri oauth-obj))
  (define response-type (oauth-response-type oauth-obj))
  
  (define url (string->url (end-points-authorization-uri end-points)))
  (define query (list (cons 'client_id (client-cred-client-id client-cred))
                      (cons 'redirect_uri redirect-uri)
                      (cons 'response_type response-type)
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

  

;;request-token : oauth string string -> hash
;;Third  step in authorization.Produces a json-object which is a hash which either contains
;;access-token or some kind of error.
(define (request-token oauth-obj #:code-or-token code-or-token 
                       #:grant-type (grant-type "authorization_code"))
  
;  (define auth-code?
;    (string=? grant-type "authorization_code"))
  
  (define refresh?
    (string=? grant-type "refresh_token"))
  
  (define (http-ok? headers)
    (regexp-match? #rx"HTTP/.* 200 OK" headers))

  (define (json-content? headers)
    (regexp-match? #rx"Content-Type.*json" headers))
  
  (define encode form-urlencoded-encode)
  (define extra-headers (list "Content-Type: application/x-www-form-urlencoded"))
  
  (define (make-post-string)
    (let ([client-cred (oauth-cc oauth-obj)]
          [redirect-uri (oauth-redirect-uri oauth-obj)])
      
      (string-append
       "client_id=" (encode (client-cred-client-id client-cred)) "&"
       "client_secret=" (encode (client-cred-client-secret client-cred)) "&"       
       "grant_type=" grant-type "&"
       (if refresh?
           (string-append "refresh_token=" (encode code-or-token))
           (string-append 
            "redirect_uri=" (encode redirect-uri) "&"
            "code=" (encode code-or-token))))))
  
  (define token-uri (end-points-token-uri (oauth-end-points oauth-obj)))
  (define in (post-impure-port (string->url token-uri) 
                               (string->bytes/utf-8 (make-post-string)) extra-headers))
  (define headers (purify-port in))
  
  (if (json-content? headers)
      (read-json in) ;; may contain error key.
      ;;instead of error maybe a exception or something else
      (error 'request-token "can't parse, header: ~a , content:~a "
             headers (port->bytes in))))
    

;;request-access-token : oauth string -> hash
(define (request-access-token oauth-obj #:code code)
  (request-token oauth-obj #:code-or-token code ))

;;Not tested
;;refresh-access-token : oauth string -> hash
(define (refresh-access-token oauth-obj #:refresh-token refresh-token)
  (request-token oauth-obj #:code-or-token refresh-token 
                 #:grant-type "refresh_token"))
  
(provide make-oauth-2
         request-owner-for-grant
         get-grant-resp request-access-token
         refresh-access-token)



  
  
  


                              
                                 
                                 