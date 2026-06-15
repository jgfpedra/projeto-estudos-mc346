;;; fractal-params.scm — primitivas de parâmetro da FractalDSL
(load "fractal-core.scm")

;; Cada primitiva devolve um novo fractal (sem mutação).
;; Isso permite encadear chamadas em pipeline funcional.

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
