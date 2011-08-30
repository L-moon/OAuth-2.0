#lang racket
(require web-server/servlet
         web-server/servlet-env)
(require (file "../../oauth-2.rkt"))
(require "authorization-handler.rkt")

;;"secret.rkt" is only used only to export oauth-obj
;; comment this and create your own oauth-obj as shown below.
(require (prefix-in private: (file "../../../secret/secret.rkt"))) 

;;import oauth-obj from some place for example secret.rkt OR
(define oauth-obj private:oauth-obj)
;;Create your own using make-oauth-2 as shown below.
;  (make-oauth-2
;   #:client-id "Your  client ID"
;   #:client-secret "Your client secret"
;   #:authorization-uri "https://accounts.google.com/o/oauth2/auth"
;   #:token-uri "https://accounts.google.com/o/oauth2/token"
;   #:redirect-uri "http://localhost:8000/oauth2callback.rkt"
;   #:response-type 'code))


;;list of services required
(define scope (list "https://www.google.com/m8/feeds"))

(define (start request)
  (show-all-contacts request))

;;retrieve all contacts of a user from google.
(define (show-all-contacts request)
  
  (define (gen-resp make-url)
    (response/xexpr
     `(html (body (h1 "Show All contacts")
                  (p (a ((href ,(make-url get-contacts))) "All contacts"))))))
  
  (define (get-contacts request)
    
    (define access-token (get-authorization oauth-obj scope))
    (define contacts (get-all-contacts access-token))
    (begin
      (printf "~a\n" contacts)
      (response/xexpr
       `(html (body (h1 "Success in retrieving contacts"))))))
    
  (send/suspend/dispatch gen-resp))



(define (get-all-contacts access-token)
  (let ([url (string->url "https://www.google.com/m8/feeds/contacts/default/full")])
    (set-url-query! url (list (cons 'access_token access-token)))
    (port->bytes (get-pure-port url
                                (list "GData-Version: 3.0")))))

(serve/servlet start #:servlet-path "/"
               #:servlets-root (current-directory))



