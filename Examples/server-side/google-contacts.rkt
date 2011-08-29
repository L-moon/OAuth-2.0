#lang racket
(require web-server/servlet
         web-server/servlet-env)
(require net/url net/uri-codec)
(require (file "../../utils/web-helper.rkt"))
(require (file "../../oauth-2.rkt"))
(require (prefix-in private: (file "../../../secret/secret.rkt")))

(define encode form-urlencoded-encode)

;;import oauth-obj from some place for example secret.rkt OR
(define oauth-obj private:oauth-obj)
;;Create your own using make-oauth-2 as shown below.
;  (make-oauth-2
;   #:client-id "abc .... blah"
;   #:client-secret "45bg......"
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
    
    (define json-obj (get-authorization oauth-obj))
    (define contacts (get-all-contacts (hash-ref json-obj 'access_token)))
    (begin
      (printf "~a\n" contacts)
      (response/xexpr
       `(html (body (h1 "Success in retrieving contacts"))))))
  
  
  (send/suspend/dispatch gen-resp))

;;Main function for authorization and access token.
(define (get-authorization oauth-obj)
  
  ;;Need to check if we are already authorized ,
  ;;may be using cookie??
  
  (define (get-code bindings)
    (if (binding-exists? 'code bindings)
        (get-value 'code bindings)
        #f))
  
  (define (get-error bindings)
    (if (binding-exists? 'error bindings)
        (get-value 'error bindings)
        #f))
  
  (define req (send/suspend
               (lambda (make-url)
                 (redirect-to 
                  (request-owner-for-grant oauth-obj 
                                           #:state (encode make-url)
                                           #:scope scope)))))
  
  (define bindings (get-bindings req))
  (define code (get-code bindings))
  (define error (get-error bindings))
  
  (if code
      
      (let ([json-obj (request-access-token oauth-obj #:code code)])
        (if (hash-ref json-obj 'error #f)
            
            (response/xexpr
             `(html (body (h1 ,(hash-ref json-obj 'error)))))
            
            json-obj))
      
      (response/xexpr
       `(html (body (h1 "Error: " ,(or (get-error bindings)
                                       "unknown error")))))))



(define (get-all-contacts access-token)
  (let ([url (string->url "https://www.google.com/m8/feeds/contacts/default/full")])
    (set-url-query! url (list (cons 'access_token access-token)))
    (port->bytes (get-pure-port url
                                (list "GData-Version: 3.0")))))


(serve/servlet start #:servlet-path "/"
               #:servlets-root (current-directory))



