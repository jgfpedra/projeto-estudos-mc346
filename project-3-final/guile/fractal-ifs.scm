;;; fractal-ifs.scm — Sistemas de Funções Iteradas + macros de composição
(load "fractal-core.scm")

;; ─── Primitivas de IFS ────────────────────────────────────────────────────

(define (affine a b c d e f)
  (list 'affine a b c d e f))

(define (transform prob aff)
  (list 'transform prob aff))

;; macro: anexa lista de transforms ao fractal
(define (ifs fractal . transforms)
  (set-field fractal 'ifs transforms))

;; macro: marca um sub-fractal com profundidade de expansão
(define (with-depth d fractal)
  (cons (cons 'depth d) fractal))

;; ─── Execução de IFS ─────────────────────────────────────────────────────

(define (fractal-with-depth? x)
  (and (list? x) (assq 'depth x)))

(define (apply-affine aff point)
  (let ((a (list-ref aff 1)) (b (list-ref aff 2))
        (c (list-ref aff 3)) (d (list-ref aff 4))
        (e (list-ref aff 5)) (f (list-ref aff 6))
        (x (car point))      (y (cadr point)))
    (list (+ (* a x) (* b y) e)
          (+ (* c x) (* d y) f))))

(define (choose-transform transforms)
  (let ((r (random:uniform)))
    (let loop ((ts transforms) (acc 0))
      (let* ((t       (car ts))
             (prob    (cadr t))
             (new-acc (+ acc prob)))
        (if (or (< r new-acc) (null? (cdr ts)))
            t
            (loop (cdr ts) new-acc))))))

(define (iterate-ifs fractal n)
  (let ((transforms (get-field fractal 'ifs)))
    (let loop ((point '(0.0 0.0)) (points '()) (i 0))
      (if (= i n)
          (reverse points)
          (let* ((t   (choose-transform transforms))
                 (val (caddr t)))
            (cond
              ((fractal-with-depth? val)
               (let* ((d       (cdr (assq 'depth val)))
                      (sub-pts (iterate-ifs val d))
                      (new-pt  (if (null? sub-pts) point
                                   (car (reverse sub-pts)))))
                 (loop new-pt (append points sub-pts) (+ i 1))))
              (else
               (let ((new-pt (apply-affine val point)))
                 (loop new-pt (cons new-pt points) (+ i 1))))))))))
