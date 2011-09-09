#lang racket
(require net/sendurl)
(require (file "../oauth-2.rkt"))

(define (get-authorization-password oauth-obj 
                                    #:scope (scope empty) 
                                    #:username username
                                    #:password password)
  (request-access-token (make-oauth-with-grant-type oauth-obj 'password)
                        #:scope scope
                        #:username username
                        #:password password))

(define (get-authorization-client-cred oauth-obj #:scope (scope empty))
  (request-access-token (make-oauth-with-grant-type oauth-obj 'client-cred)
                        #:scope scope))

(define (get-authorization-refresh-token oauth-obj #:refresh-token refresh-token)
  (request-access-token (make-oauth-with-grant-type oauth-obj 'refresh-token)
                        #:refresh-token refresh-token))

(define (get-authorization-native oauth-obj scope code-reader)
  #f)

(define (get-authorization-local-browser oauth-obj #:scope (scope empty))
  (send-url 
   (request-authorization-code oauth-obj #:scope scope) #:escape? #f)
  (display "code : ")
  (define code (read-line))
  (request-access-token oauth-obj #:code code))

  


(provide (all-defined-out))

                        