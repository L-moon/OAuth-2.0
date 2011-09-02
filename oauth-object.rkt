#lang racket

(provide get-authorization-uri get-token-uri get-client-id
         get-client-secret get-redirect-uri get-response-type
         make-oauth-2 oauth-object? get-grant-type)


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

;;A basic oauth structure
(struct oauth (cc end-points redirect-uri grant-type)) ; where
;;cc is client-cred structure
;;redirect-uri is a string representation of a url
;;response-type is a string 

;;Constructor for oauth structure.
(define (make-oauth-2 #:client-id client-id
                      #:client-secret client-secret
                      #:authorization-uri authorization-uri
                      #:token-uri token-uri
                      #:redirect-uri redirect-uri
                      #:grant-type (grant-type 'authorization-code))
  
  (define check-grant-type
    (case grant-type
      [(authorization-code token password client-cred) #t]
      [else #f]))
  
  (if check-grant-type 
      (oauth (client-cred client-id client-secret)
             (end-points authorization-uri token-uri)
             redirect-uri
             grant-type)
      (error 'make-oauth-2 "invalid grant type ~a" grant-type)))





(define (oauth-object? obj)
  (oauth? obj))

         
;;functions to extract the field of oauth-obj
(define (get-authorization-uri oauth-obj)
  (end-points-authorization-uri (oauth-end-points oauth-obj)))

(define (get-token-uri oauth-obj)
  (end-points-token-uri (oauth-end-points oauth-obj)))

(define (get-client-id oauth-obj)
  (client-cred-client-id (oauth-cc oauth-obj)))

(define (get-client-secret oauth-obj)
  (client-cred-client-secret (oauth-cc oauth-obj)))

(define (get-redirect-uri oauth-obj)
  (oauth-redirect-uri oauth-obj))

(define (get-grant-type oauth-obj)
  (oauth-grant-type oauth-obj))

(define (get-response-type oauth-obj)
  (let ([grant-type (get-grant-type oauth-obj)])
    (case grant-type
      [(authorization-code) "code"]
      [(token) "token"]
      [else #f])))

;(begin
;  (define oauth-obj  (make-oauth-2
;                      #:client-id "abc .... blah"
;                      #:client-secret "45bg......"
;                      #:authorization-uri "https://accounts.google.com/o/oauth2/auth"
;                      #:token-uri "https://accounts.google.com/o/oauth2/token"
;                      #:redirect-uri "http://localhost:8000/oauth2callback.rkt"
;                      #:grant-type 'authorization-code))
;  (list (get-authorization-uri oauth-obj)
;        (get-token-uri oauth-obj)
;        (get-client-id oauth-obj)
;        (get-client-secret oauth-obj)
;        (get-redirect-uri oauth-obj)
;        (get-response-type oauth-obj)))