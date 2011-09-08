#lang racket
(require (planet vyzo/crypto:2:3))
(require net/url net/uri-codec net/base64)

(define key (random-bytes (digest-size digest:sha1)))

(define (encode-state uri)
  (define uri-bytes (string->bytes/utf-8 uri))
  (define digest (hmac digest:sha1 key uri-bytes))
  (define a-state (base64-encode (bytes-append digest uri-bytes)))
  (bytes->string/utf-8 a-state))


(define (decode-state state)
  (define state-bytes (string->bytes/utf-8 state))
  (define state-decode (base64-decode state-bytes))
  
  (if (<= (bytes-length state-decode) 20)
      #f
      (let ([digest (subbytes state-decode 0 20)]
            [uri-bytes (subbytes state-decode 20)])
        (if (equal? digest (hmac digest:sha1 key uri-bytes))
            (bytes->string/utf-8 uri-bytes)
            #f))))

(begin
  (printf "state.rkt\n"))

(provide decode-state encode-state)
