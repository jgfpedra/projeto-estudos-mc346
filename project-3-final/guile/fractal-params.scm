(load "fractal-core.scm")

(define-syntax fractal-pipe
  (syntax-rules ()
    ((_ init) init)
    ((_ init (fn args ...) rest ...)
     (fractal-pipe (fn init args ...) rest ...))))

(define (equation fractal expr-str)
  (set-field fractal 'equation expr-str))

(define (constant fractal name value)
  (let ((cs (get-field fractal 'constants)))
    (set-field fractal 'constants
      (cons (cons name value)
            (if (eq? cs #nil) '() cs)))))

(define (iterations fractal n)
  (set-field fractal 'iterations n))

(define (center fractal re im)
  (set-field fractal 'center (list re im)))

(define (zoom fractal z)
  (set-field fractal 'zoom z))

(define (resolution fractal w h)
  (set-field fractal 'resolution (list w h)))

(define (color fractal scheme)
  (set-field fractal 'color scheme))
