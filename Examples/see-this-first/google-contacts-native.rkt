#lang racket
(require net/url)
(require (file "../../authorization.rkt"))


(define oauth-obj
  (make-oauth-2
   #:client-id "Your client id"
   #:client-secret "Your client secret"
   #:authorization-uri "https://accounts.google.com/o/oauth2/auth"
   #:token-uri "https://accounts.google.com/o/oauth2/token"
   #:redirect-uri "urn:ietf:wg:oauth:2.0:oob"))




(define scope (list "https://www.google.com/m8/feeds"))

(define (get-all-contacts access-token)
  (let ([url (string->url "https://www.google.com/m8/feeds/contacts/default/full")])
    (set-url-query! url (list (cons 'access_token access-token)))
    (port->bytes (get-pure-port url
                                (list "GData-Version: 3.0")))))

(define access-token-hash (get-authorization-local-browser oauth-obj #:scope scope))

(get-all-contacts (hash-ref access-token-hash 'access_token))



  

  
  