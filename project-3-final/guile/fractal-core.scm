;;; fractal-core.scm — estrutura de dados e aritmética complexa

;; ─── Estrutura do fractal (association list) ───────────────────────────────

(define (create-fractal name)
  (list
    `(name       . ,name)
    '(equation   . #nil)
    '(constants  . ())
    '(iterations . 0)
    '(center     . (0 0))
    '(zoom       . 100)))

(define (set-field fractal field value)
  (map (lambda (sublist)
         (if (eq? (car sublist) field)
             (cons field value)
             sublist))
       fractal))

(define (get-field fractal field)
  (let ((result (assq field fractal)))
    (if result (cdr result) #nil)))

;; ─── Aritmética complexa ───────────────────────────────────────────────────

(define (make-c r i) (cons r i))
(define (c-real z)   (car z))
(define (c-imag z)   (cdr z))

(define (c+ a b)
  (make-c (+ (c-real a) (c-real b))
          (+ (c-imag a) (c-imag b))))

(define (c- a b)
  (make-c (- (c-real a) (c-real b))
          (- (c-imag a) (c-imag b))))

(define (c* a b)
  (make-c (- (* (c-real a) (c-real b)) (* (c-imag a) (c-imag b)))
          (+ (* (c-real a) (c-imag b)) (* (c-imag a) (c-real b)))))

(define (c-abs z)
  (sqrt (+ (* (c-real z) (c-real z)) (* (c-imag z) (c-imag z)))))

(define (c-pow z n)
  (if (= n 0) (make-c 1 0) (c* z (c-pow z (- n 1)))))
