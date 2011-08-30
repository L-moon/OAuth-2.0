#lang racket

(require web-server/servlet
         web-server/servlet-env)
(require (file "../../oauth-2.rkt"))
(require "authorization-handler.rkt")

(require (prefix-in private: (file "../../../secret/secret.rkt")))

(define oauth-obj private:facebook-oauth-obj)
  
;;list of services required
(define scope (list "email"))

(define (start request)
  (show-graph request))

;;retrieve all contacts of a user from google.
(define (show-graph request)
  
  (define (gen-resp make-url)
    (response/xexpr
     `(html (body (h1 "Show graph")
                  (p (a ((href ,(make-url get-graph))) "Get Graph"))))))
  
  (define (get-graph request)        
    (define access-token (get-authorization oauth-obj scope))
    (define graph (get-graph-data access-token))
    (begin
      (printf "~a\n" graph)
      (response/xexpr
       `(html (body (h1 "Success in retrieving graph"))))))
  
  
  (send/suspend/dispatch gen-resp))


(define (get-graph-data access-token)
  (let ([url (string->url "https://graph.facebook.com/me")])
    (set-url-query! url (list (cons 'access_token access-token)))
    (port->bytes (get-pure-port url))))
                                


(serve/servlet start #:servlet-path "/"
               #:servlets-root (current-directory))

