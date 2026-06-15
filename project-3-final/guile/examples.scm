;;;; examples.scm — os quatro exemplos do README + ilha fractal
(load "fractal-generate.scm")
(load "fractal-params.scm")

;;; ─── 1. Mandelbrot ───────────────────────────────────────────────────────

;;;(define mandelbrot
;;;  (zoom
;;;    (center
;;;      (iterations
;;;        (equation (create-fractal "Mandelbrot") "z=z^2+c")
;;;        500)
;;;      -0.5 0)
;;;    200))

;;; ─── 2. Julia ─────────────────────────────────────────────────────────────

;;(define julia
;;  (zoom
;;    (center
;;      (constant
;;        (iterations
;;          (equation (create-fractal "Julia") "z=z^2+c")
;;          500)
;;        'c (cons -0.4 0.6))
;;      0 0)
;;    150))

;;; ─── 3. Sierpinski ───────────────────────────────────────────────────────

;;(define sierpinski
;;  (iterations
;;    (ifs (create-fractal "Sierpinski")
;;      (transform 0.33 (affine 0.5 0.0 0.0 0.5 0.0  0.0))
;;      (transform 0.33 (affine 0.5 0.0 0.0 0.5 0.5  0.0))
;;      (transform 0.34 (affine 0.5 0.0 0.0 0.5 0.25 0.5)))
;;    10000))


;;; ─── 4. Barnsley Fern (base da ilha) ─────────────────────────────────────

;;;(define barnsley
;;  (iterations
;;    (ifs (create-fractal "BarnsleyFern")
;;      (transform 0.01 (affine  0.00  0.00  0.00  0.16  0.00  0.00))
;;      (transform 0.85 (affine  0.85  0.04 -0.04  0.85  0.00  1.60))
;;      (transform 0.07 (affine  0.20 -0.26  0.23  0.22  0.00  1.60))
;;      (transform 0.07 (affine -0.15  0.28  0.26  0.24  0.00  0.44)))
;;    90000))

;;; ─── 5. Ilha — IFS com ramos compostos via with-depth ────────────────────

(define sierpinski-base
  (ifs (create-fractal "Sierpinski")
    (transform 0.33 (affine 0.5 0.0 0.0 0.5 0.0  0.0))
    (transform 0.33 (affine 0.5 0.0 0.0 0.5 0.5  0.0))
    (transform 0.34 (affine 0.5 0.0 0.0 0.5 0.25 0.5))))

(define barnsley-base
  (ifs (create-fractal "BarnsleyFern")
    (transform 0.01 (affine  0.00  0.00  0.00  0.16  0.00  0.00))
    (transform 0.85 (affine  0.85  0.04 -0.04  0.85  0.00  1.60))
    (transform 0.07 (affine  0.20 -0.26  0.23  0.22  0.00  1.60))
    (transform 0.07 (affine -0.15  0.28  0.26  0.24  0.00  0.44))))

(define ilha-ficticia
  (iterations
    (ifs (create-fractal "IlhaFicticia")
      (transform 0.4 (affine  0.6  0.1 -0.1  0.5  0.0  0.0))
      (transform 0.15 (affine  0.4  0.0  0.0  0.4 -0.3  0.2))
      (transform 0.15 (affine  0.4  0.0  0.0  0.4  0.3 -0.2))
      (transform 0.2 (affine  0.3 -0.2  0.2  0.3  0.0  0.1))
      (transform 0.1 (affine  0.2  0.0  0.0  0.5  0.1  0.4)))
    40000))

(export-csv ilha-ficticia "ilha.csv")

