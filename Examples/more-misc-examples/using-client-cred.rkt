#lang racket
(require net/url)
(require (file "../../oauth-2.rkt"))

(require (prefix-in private: (file "../../../secret/secret.rkt")))

(define oauth-obj private:facebook-oauth-obj-client-cred)

;(define facebook-oauth-obj  
;  (make-oauth-2
;   #:client-id "Your client id"
;   #:client-secret "Your client secret"
;   #:authorization-uri "https://www.facebook.com/dialog/oauth"
;   #:token-uri "https://graph.facebook.com/oauth/access_token"
;   #:redirect-uri "http://localhost:8000/oauth2callback.rkt"
;   #:grant-type 'client-cred))

;;Note the change of grant type in make-oauth-2 

(define scope (list "email"))

(define (get-graph-data access-token)
  (let ([url (string->url "https://graph.facebook.com/me")])
    (set-url-query! url (list (cons 'access_token access-token)))
    (port->bytes (get-pure-port url))))

;;when grant-type is 'client-cred , we can directly 
;;request access token , since in a way we are requesting
;;our own resource. 

(let ([a-hash (request-access-token oauth-obj #:scope scope)])
  (let ([access-token (hash-ref a-hash 'access_token #f)])
    (when access-token
      (get-graph-data access-token))))

