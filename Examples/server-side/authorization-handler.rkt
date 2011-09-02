#lang racket
(require web-server/http)
(require web-server/servlet/web)
(require net/uri-codec)
(require (file "../../utils/web-helper.rkt"))
(require (file "../../oauth-2.rkt"))

(provide get-authorization)

(define encode form-urlencoded-encode)

;;Two steps :
;; 1. request authorization code
;; 2. request access token 

;;get-authorization : oauth (listof string) -> string
;;returns access token by 
;;1. first requesting authorization code and then
;;2. requesting access token by passing authorization code
(define (get-authorization oauth-obj scope)
        
  (define req (send/suspend
               (lambda (make-url)
                 (redirect-to 
                  (request-authorization-code oauth-obj 
                                           #:state (encode make-url)
                                           #:scope scope)))))
  
  (define bindings (get-bindings req))
  
  (define code 
    (cond
      [(binding-exists? 'code bindings) (get-value 'code bindings)]
      [else #f]))
  
  (define authorization-error 
    (cond
      [(binding-exists? 'error bindings) (get-value 'error bindings)]
      [else #f]))
  
  (define (get-access-token code)
    (let* ([json-obj (request-access-token oauth-obj #:code code)]
           [access-error (hash-ref json-obj 'error #f)])
      (if access-error
          (send/back
           (response/xexpr
            `(html (body (h1 "Error in getting access-token : "
                             ,(hash-ref json-obj 'error))))))
          (hash-ref json-obj 'access_token))))
  
          
          
    (if code
        (get-access-token code)
        (send/back 
         (response/xexpr
          `(html (body (h1 "Error in authorization : " 
                           ,(or authorization-error
                                "unknown error"))))))))

          
  