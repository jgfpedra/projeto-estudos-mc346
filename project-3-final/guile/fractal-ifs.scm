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
  (and (list? x)
       (pair? (car x))
       (assq 'depth x)))

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

(define (iterate-ifs-from transforms n)
  ;; Like iterate-ifs but takes a flat transforms list directly,
  ;; starts at the origin, returns the point cloud.
  (let loop ((point '(0.0 0.0))
             (points '())
             (i 0)
             (stack (list (cons transforms n))))
    (cond
      ((= i n) (reverse points))
      ((null? stack) (reverse points))
      (else
       (let* ((top        (car stack))
              (ts         (car top))
              (remaining  (cdr top)))
         (if (= remaining 0)
             (loop point points i (cdr stack))
             (let* ((t   (choose-transform ts))
                    (val (caddr t)))
               (cond
                 ((fractal-with-depth? val)
                  (let* ((d           (cdr (assq 'depth val)))
                         (sub-ts      (get-field val 'ifs))
                         (new-stack   (cons (cons sub-ts d)
                                            (cons (cons ts (- remaining 1))
                                                  (cdr stack)))))
                    (loop point points i new-stack)))
                 (else
                  (let ((new-pt (apply-affine val point)))
                    (loop new-pt (cons new-pt points) (+ i 1)
                          (cons (cons ts (- remaining 1)) (cdr stack)))))))))))))

(define (iterate-ifs fractal n)
  (let ((root-transforms (get-field fractal 'ifs)))
    (let loop ((point '(0.0 0.0))
               (points '())
               (i 0)
               (stack (list (cons root-transforms n))))
      (cond
        ((= i n) (reverse points))
        ((null? stack) (reverse points))
        (else
         (let* ((top         (car stack))
                (transforms  (car top))
                (remaining   (cdr top)))
           (if (= remaining 0)
               (loop point points i (cdr stack))
               (let* ((t   (choose-transform transforms))
                      (val (caddr t)))
                 (cond
                   ((fractal-with-depth? val)
                    (let* ((d (cdr (assq 'depth val)))
                           (sub-transforms (get-field val 'ifs))
                           (new-stack (cons (cons sub-transforms d)
                                             (cons (cons transforms (- remaining 1))
                                                   (cdr stack)))))
                      (loop point points i new-stack)))
                   (else
                    (let ((new-pt (apply-affine val point)))
                      (loop new-pt (cons new-pt points) (+ i 1)
                            (cons (cons transforms (- remaining 1)) (cdr stack))))))))))))))
