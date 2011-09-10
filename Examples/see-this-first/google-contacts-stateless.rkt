#lang web-server

(require web-server/servlet-env)
(require (file "../../authorization.rkt"))


(define oauth-obj 
  (make-oauth-2
   #:client-id "Your client id"
   #:client-secret "Your client secret"
   #:authorization-uri "https://accounts.google.com/o/oauth2/auth"
   #:token-uri "https://accounts.google.com/o/oauth2/token"
   #:redirect-uri "http://localhost:8000/oauth2callback.rkt"))
   

(define scope (list "https://www.google.com/m8/feeds"))

(define (start request)
  (show-contacts request))

(define (show-contacts request)
  
  (define req (send/suspend
               (lambda (a-url)
                 (response/xexpr
                  `(html 
                    (body (h1 "Show All contacts")
                          (p (a ((href ,a-url )) "All contacts"))))))))
  
  (define access-token-hash (stateless:get-authorization-web-flow oauth-obj #:scope scope))
  
  (define contacts (get-all-contacts (hash-ref access-token-hash 'access_token)))
  
  (response/full
   200 #"Okay"
   (current-seconds) #"text/xml" 
   empty
   (list contacts)))


(define (get-all-contacts access-token)
  (let ([url (string->url "https://www.google.com/m8/feeds/contacts/default/full")])
    (set-url-query! url (list (cons 'access_token access-token)))
    (port->bytes (get-pure-port url
                                (list "GData-Version: 3.0")))))
  


;;google don't link big urls??
(define (make-a-stuffer)
  (define (is-url-too-big? v)
    (> (bytes-length v) 500))
  
  (stuffer-chain
   serialize-stuffer
   is-url-too-big?
   (stuffer-chain
    gzip-stuffer
    base64-stuffer)
   is-url-too-big?
   (md5-stuffer (build-path
                 (find-system-path 'home-dir)
                 ".urls"))))


(serve/servlet start 
               #:stateless? #t 
               #:stuffer (make-a-stuffer)
               #:servlet-namespace 
               (list 
                '(file "../../authorization.rkt"))                
               #:file-not-found-responder may-be-callback)



  
  
  