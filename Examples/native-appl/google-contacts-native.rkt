#lang racket
(require net/url)
(require net/sendurl)
(require (file "../../oauth-2.rkt"))
(require (prefix-in private: (file "../../../secret/secret.rkt")))

(define oauth-obj private:native-oauth-obj)
(define scope (list "https://www.google.com/m8/feeds"))

(define (get-all-google-contacts oauth-obj)
  (begin 
    (send-url 
     (request-authorization-code oauth-obj #:scope scope) #:escape? #f)
    ;;enter the code in quotes " ..... "
    (define code (read))
    (define json-obj (request-access-token oauth-obj #:code code))
    (define access-token (hash-ref json-obj 'access_token #f))    
    (if access-token
        (get-all-contacts access-token)
        (error 'oops "dumping json object ~a" json-obj))))

(define (get-all-contacts access-token)
  (let ([url (string->url "https://www.google.com/m8/feeds/contacts/default/full")])
    (set-url-query! url (list (cons 'access_token access-token)))
    (port->bytes (get-pure-port url
                                (list "GData-Version: 3.0")))))

      
(get-all-google-contacts  oauth-obj)

