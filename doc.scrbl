#lang scribble/manual
@(require racket)
@(require racket/sandbox scribble/eval)
@;directly copied from racket docs

@(define my-evaluator
   (call-with-trusted-sandbox-configuration
    (lambda ()
      (parameterize ([sandbox-output 'string]
                     [sandbox-error-output 'string])
        (make-evaluator 'racket
                        #:requires 
                        (list "oauth-2.rkt"))))))


@title{OAuth-2.0 Client Documentation}
@bold{STATUS:
      
      Currently the three basic api's are in place and one can use them to build
      server-side , client side , and native application side flow.
      However more abstract mechanism is required to simplify its use.
      This Documentation is still incomplete and confusing :(
      
      }


OAuth-2.0 Client library allows you to use OAuth-2.0 protocol for
requesting authorization from a user to access it's resource.

At present it support all four  authorization grant : 
authorization code,implicit,resource owner password credentials and
client credentials.



Before using the api's , you will need to register as client with appropiate
authorization server. 

You will need to provide a absolute url called redirect uri.
In return you will get client credentials namely 
client identifier and client secret. 

You will also require authorization url for making authorization request and 
token url for making access token request , these should be document by authorization
server.

@defproc[(make-oauth-2 (#:client-id client-id string?)
                       (#:client-secret client-secret string?)
                       (#:authorization-uri authorization-uri string?)
                       (#:token-uri token-uri string?)
                       (#:redirect-uri redirect-uri string?)
                       (#:grant-type grant-type (and/c symbol? (one-of
                                                                'authorization-code
                                                                'token
                                                                'password
                                                                'client-cred))
                                     'authorization-code))
         oauth-object?]{
Returns object of type oauth-object?. It encapsulate most of information
that is required by other function.}

@examples[#:eval my-evaluator 
                 
                 (make-oauth-2 #:client-id "Your client id"
                               #:client-secret "Your client secret!"
                               #:authorization-uri "https://accounts.google.com/o/oauth2/auth"
                               #:token-uri "https://accounts.google.com/o/oauth2/token"
                               #:redirect-uri "http://localhost:8000/callback.rkt")]

@defproc[(request-authorization-code (oauth-obj oauth-object?) 
                                  (#:state state (or/c string? #f) #f)
                                  (#:scope scope (listof string?) empty)
                                  (#:request-method request-method 
                                                   (-> string? any/c) 
                                                   (lambda (v) v))
                                  ) any/c]{
Makes a request for authorization code to authorization server.
Default behaviour is to just return a string representation of a url, which then can
be used to redirect to it or pasted in a browser.
The @racket[grant-type] in @racket[oauth-obj] 
must be @racket[(oneof 'authorization-code 'token)]

@racket[scope] is list of serivce to access . 
Example scope is  @defthing[scope (list "https://www.google.com/m8/feeds/")]
             
@racket[state] is a used to maintain the local state and is optional. 
@racket[request-method] is a function , which is used to send the 
request to authorization server. One can use @racket[redirect-to] or
@racket[send-url] functions as request-method.
}

Authorization server may respond by redirecting to our redirect-uri.

@defproc[(get-grant-resp (request request?))
         (values (or/c string? #f) (or/c string? #f) (or/c string? #f))]{

This function parse the get request from the authorization server and
returns three values: code , state and error. Where code is authorization code
and state is same as passed to request-authorization-code and error is error returned
by authorization server. This function is normally used in web application, specially
when authorization server redirects to your redirect uri.}
                                                                        
@defproc[(request-access-token (oauth-obj oauth-obj?)
                              (#:code code (or/c string? #f) #f)
                              (#:username username (or/c string? #f) #f)
                              (#:password password (or/c string? #f) #f)
                              (#:scope scope (listof string?) empty))
         hash?]{
Returns a @racket[hash] which may contain key @racket['access_token] which can be 
refrenced to get the access token. Otherwise it will contain key @racket['error] which when refrenced
will return the type of error.
                
When @racket[grant-type] is @racket['authorization-code] , then @racket[username],
 @racket[password] and @racket[scope] is ignored.
 
When @racket[grant-type] is @racket['client-cred] ,then @racket[code], @racket[username],
 @racket[password] is ignored.
 
When @racket[grant-type] is @racket['password],then @racket[code] is ignored.

}
               
                                                                                                                                        