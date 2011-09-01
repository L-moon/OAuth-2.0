#lang racket
(require web-server/http)
;(require web-server/http/redirect)
(require web-server/managers/none)
(require net/url net/uri-codec)
(require (file "../../oauth-2.rkt"))
(define interface-version 'v2)
(define manager (create-none-manager #f))
(provide interface-version manager start)

(define (start request)
  ;;we are here means authorization server has send something
  (let-values ([(code state error) (get-grant-resp request)])
    ;;state here is assumed to be a continuation url
    (if state
        (let ([url (string->url (form-urlencoded-decode state))])
          (set-url-query! url (list 
                               (if code 
                                   (cons 'code code)
                                   (cons 'error error))))
          ;;back to our continuation url i.e where we left.
          (redirect-to (url->string url) permanently))
        
         (response/xexpr
          `(html (body (h1 "no redirect uri found")))))))

        
    