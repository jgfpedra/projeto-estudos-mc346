;;; examples.scm — os quatro exemplos do README + ilha fractal
(load "fractal-generate.scm")
(load "fractal-params.scm")

;; ─── 1. Mandelbrot ───────────────────────────────────────────────────────

(define mandelbrot
  (zoom
    (center
      (iterations
        (equation (create-fractal "Mandelbrot") "z=z^2+c")
        500)
      -0.5 0)
    200))

;; ─── 2. Julia ─────────────────────────────────────────────────────────────

(define julia
  (zoom
    (center
      (constant
        (iterations
          (equation (create-fractal "Julia") "z=z^2+c")
          500)
        'c (cons -0.4 0.6))
      0 0)
    150))

;; ─── 3. Sierpinski ───────────────────────────────────────────────────────

(define sierpinski
  (iterations
    (ifs (create-fractal "Sierpinski")
      (transform 0.33 (affine 0.5 0.0 0.0 0.5 0.0  0.0))
      (transform 0.33 (affine 0.5 0.0 0.0 0.5 0.5  0.0))
      (transform 0.34 (affine 0.5 0.0 0.0 0.5 0.25 0.5)))
    50000))

;; ─── 4. Barnsley Fern (base da ilha) ─────────────────────────────────────

(define barnsley
  (iterations
    (ifs (create-fractal "BarnsleyFern")
      (transform 0.01 (affine  0.00  0.00  0.00  0.16  0.00  0.00))
      (transform 0.85 (affine  0.85  0.04 -0.04  0.85  0.00  1.60))
      (transform 0.07 (affine  0.20 -0.26  0.23  0.22  0.00  1.60))
      (transform 0.07 (affine -0.15  0.28  0.26  0.24  0.00  0.44)))
    100000))

;; ─── 5. Ilha — IFS com ramos compostos via with-depth ────────────────────
;;
;; A "ilha" é um fractal composto: o litoral usa o Sierpinski triangular
;; (costa recortada) e o interior usa a sámara de Barnsley (vegetação).
;; Cada ramo é expandido até uma profundidade própria.

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

(define ilha
  (iterations
    (ifs (create-fractal "Ilha")
      (transform 0.5 (with-depth 12 sierpinski-base))   ; litoral recortado
      (transform 0.5 (with-depth  8 barnsley-base)))     ; vegetação interior
    20000))

;; ─── Exporta CSVs para o renderer Python ─────────────────────────────────

(display "sierpinski ifs field: ")
(display (get-field sierpinski 'ifs))
(newline)
(export-csv sierpinski "sierpinski.csv")
(export-csv barnsley   "barnsley.csv")
(export-csv ilha       "ilha.csv")

(display "CSVs gerados: sierpinski.csv, barnsley.csv, ilha.csv\n")
