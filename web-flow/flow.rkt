#lang racket
(require web-server/http)
(require web-server/servlet/web)
(require (file "../oauth-2.rkt"))
(require "state.rkt")
(provide get-authorization-web-flow)

(define (get-authorization-web-flow oauth-obj #:scope (scope #f))
  
  (define req (send/suspend
               (lambda (a-url)
                 (redirect-to
                  (request-authorization-code oauth-obj
                                              #:state (encode-state a-url)
                                              #:scope scope)))))
  
  (define-values (code _ auth-error) (get-grant-resp req))
  
  (cond    
    [auth-error (raise 
                 (exn:fail:authorization 
                  (format "authorization-resp-error: ~a" auth-error)
                  (current-continuation-marks)
                  'authorization-response))]
    
    [code (request-access-token oauth-obj #:code code)]
    [else (exn:fail:authorization 
           "authorization-resp-error: No code , No error"
           (current-continuation-marks)
           'authorization-response)]))

  
  