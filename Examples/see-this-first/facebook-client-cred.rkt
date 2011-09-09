#lang racket
(require net/url)
(require (file "../../authorization.rkt"))



(define oauth-obj  
  (make-oauth-2
   #:client-id "Your client id"
   #:client-secret "Your client secret"
   #:authorization-uri "https://www.facebook.com/dialog/oauth"
   #:token-uri "https://graph.facebook.com/oauth/access_token"
   #:redirect-uri "http://localhost:8000/oauth2callback.rkt"))




;;note : You need to insert client id here too
(define analytic-uri 
  (string-append
   "https://graph.facebook.com/" Your-client-id "/insights"))



(define (get-analytic-data access-token )
  (let ([url (string->url analytic-uri)])
    (set-url-query! url (list (cons 'access_token access-token)))
    (port->bytes (get-pure-port url))))

(define access-token-hash (get-authorization-client-cred oauth-obj))
(get-analytic-data (hash-ref access-token-hash 'access_token))

