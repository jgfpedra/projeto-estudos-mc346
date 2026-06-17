;;; fractal-generate.scm — parser de equação + ponto de entrada `generate`
(load "fractal-core.scm")
(load "fractal-ifs.scm")
(load "fractal-coastline.scm")

;; ─── Parser mínimo ────────────────────────────────────────────────────────

(define (parse-exponent s)
  (let ((hat (string-contains s "^")))
    (and hat
         (let* ((rest  (substring s (+ hat 1)))
                (plus  (string-contains rest "+"))
                (minus (string-contains rest "-"))
                (end   (or plus minus (string-length rest))))
           (string->number (substring rest 0 end))))))

(define (parse-expr str)
  (let ((s (string-trim str)))
    (cond
      ((and (string-contains s "z^") (string-contains s "+c"))
       (let ((n (parse-exponent s)))
         (lambda (z c) (c+ (c-pow z n) c))))
      ((and (string-contains s "z^") (string-contains s "-c"))
       (let ((n (parse-exponent s)))
         (lambda (z c) (c- (c-pow z n) c))))
      ((string-contains s "z^")
       (let ((n (parse-exponent s)))
         (lambda (z c) (c-pow z n))))
      ((string=? s "z*z+c")
       (lambda (z c) (c+ (c* z z) c)))
      (else (error "Equação não reconhecida" str)))))

(define (parse-equation str)
  (let* ((sides (string-split str #\=))
         (rhs   (string-trim (cadr sides))))
    (parse-expr rhs)))

;; ─── Motor de escape ─────────────────────────────────────────────────────

(define (iterate-equation f max-iter c)
  (let loop ((z (make-c 0.0 0.0)) (i 0))
    (cond ((= i max-iter) i)
          ((> (c-abs z) 2.0) i)
          (else (loop (f z c) (+ i 1))))))

;; ─── Ponto de entrada ────────────────────────────────────────────────────

(define (generate fractal)
  (let ((eq-str        (get-field fractal 'equation))
        (ifs-val       (get-field fractal 'ifs))
        (coastline-val (get-field fractal 'coastline))
        (iters         (get-field fractal 'iterations)))
    (cond
      ((not (eq? coastline-val #nil))
       (generate-island coastline-val))
      ((not (eq? ifs-val #nil))
       (iterate-ifs fractal iters))
      ((string? eq-str)
       (let ((f (parse-equation eq-str)))
         (iterate-equation f iters (make-c 0.0 0.0))))
      (else
       (error "Fractal sem equation nem ifs"
              (get-field fractal 'name))))))

;; ─── Exporta pontos para CSV ──────────────────────────────────────────────

(define (export-csv fractal filename)
  (let ((result (generate fractal)))
    (call-with-output-file filename
      (lambda (port)
        (display "x,y,type\n" port)
        (define (write-pts pts label)
          (for-each
            (lambda (p)
              (display (car p)  port) (display "," port)
              (display (cadr p) port) (display "," port)
              (display label    port) (newline port))
            pts))
        ;; generate-island returns (coast-points . decor-points)
        ;; everything else returns a flat list of points
        (if (and (pair? result)
                 (pair? (car result))
                 (list? (caar result)))
            (begin
              (write-pts (car result) "coast")
              (write-pts (cdr result) "decor"))
            (write-pts result "point"))))))
