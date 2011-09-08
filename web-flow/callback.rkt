#lang racket
(require setup/dirs)
(require web-server/configuration/responders)
(require net/url)
(require web-server/http)
(require (file "../oauth-2.rkt"))
(require "state.rkt")


(define default-server-root (build-path (find-collects-dir)
                                        "web-server"
                                        "default-web-root"))

(define file-not-found (gen-file-not-found-responder
                        (build-path
                         default-server-root
                         "conf"
                         "not-found.html")))

(define (may-be-callback request)
  (define-values (code state err) (get-grant-resp request))
  
  (define (redirect-to-state uri)
            
    (cond
      [uri (let ([url (string->url uri)])
             (set-url-query! url (list
                                  (cons 'code code)
                                  (cons 'error err)))
             (redirect-to (url->string url) permanently))]
      [else (file-not-found request)]))
  
  (cond
    [state (redirect-to-state (decode-state state))]
    [else (file-not-found request)]))

  
  
        

(provide may-be-callback)
