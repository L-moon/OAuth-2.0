OAuth 2.0 client library
==========================================

A Simple implementation of OAuth-2.0 client protocol in Racket

Currently lib is usable but no documentation yet.

For examples see Example directory.

Objects
========
1. *oauth-object* : encapsulate commonly required information for protocol.

	```scheme
	(define oauth-obj 
	  (make-oauth-2
	   #:client-id "Your client id"
	   #:client-secret "Your client secret"
	   #:authorization-uri "https://accounts.google.com/o/oauth2/auth"
	   #:token-uri "https://accounts.google.com/o/oauth2/token"
	   #:redirect-uri "http://localhost:8000/oauth2callback.rkt"))
	```


	
High Level Api's
=================
1. ```scheme
(get-authorization-web-flow oauth-obj #:scope scope)
```

2. ```scheme
(get-authorization-password oauth-obj 
                                    #:scope (scope empty) 
                                    #:username username
                                    #:password password) 
```

3. ```scheme
(get-authorization-client-cred oauth-obj #:scope (scope empty))
```

4. ```scheme
(get-authorization-local-browser oauth-obj #:scope (scope empty))
```

All of them returns *hash object* , which may contains access_token

```scheme
(define access-token-hash (get-authorization-client-cred oauth-obj))
(hash-ref access-token-hash 'access_token)
```



Low Level Api's 
=================
See oauth-2.rkt




Example of Web flow using statefull servlet from example dir.
============================
```scheme
#lang racket

(require web-server/servlet
         web-server/servlet-env)

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
  
  (define access-token-hash (get-authorization-web-flow oauth-obj #:scope scope))
  
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
  


 (serve/servlet start 
                #:servlet-namespace 
                (list 
                 '(file "../../authorization.rkt"))
                #:file-not-found-responder may-be-callback)
```

