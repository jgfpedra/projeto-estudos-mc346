(load "fractal-dsl-reader.scm")

;; ─── Mandelbrot ───────────────────────────────────────────────────────────
(fractal Mandelbrot
  (dsl-equation "z=z^2+c")
  (dsl-iterations 500)
  (dsl-center -0.5 0)
  (dsl-zoom 200))

;; ─── Julia ────────────────────────────────────────────────────────────────
(fractal Julia
  (dsl-equation "z=z^2+c")
  (dsl-constant c (cons -0.4 0.6))
  (dsl-iterations 500)
  (dsl-center 0 0)
  (dsl-zoom 150))

;; ─── Sierpinski ───────────────────────────────────────────────────────────
(fractal Sierpinski
  (dsl-ifs
    (transform 0.33 (affine 0.5 0.0 0.0 0.5 0.0  0.0))
    (transform 0.33 (affine 0.5 0.0 0.0 0.5 0.5  0.0))
    (transform 0.34 (affine 0.5 0.0 0.0 0.5 0.25 0.5)))
  (dsl-iterations 50000))

;; ─── Ilha ─────────────────────────────────────────────────────────────────
(fractal Ilha
  (dsl-ifs
    (transform 0.5 (with-depth 8
      (ifs (create-fractal "Sierpinski")
        (transform 0.33 (affine 0.5 0.0 0.0 0.5 0.0  0.0))
        (transform 0.33 (affine 0.5 0.0 0.0 0.5 0.5  0.0))
        (transform 0.34 (affine 0.5 0.0 0.0 0.5 0.25 0.5)))))
    (transform 0.5 (with-depth 6
      (ifs (create-fractal "Barnsley")
        (transform 0.01 (affine  0.00  0.00  0.00  0.16  0.00  0.00))
        (transform 0.85 (affine  0.85  0.04 -0.04  0.85  0.00  1.60))
        (transform 0.07 (affine  0.20 -0.26  0.23  0.22  0.00  1.60))
        (transform 0.07 (affine -0.15  0.28  0.26  0.24  0.00  0.44))))))
  (dsl-iterations 40000))

;; ─── Exporta ──────────────────────────────────────────────────────────────
(generate Ilha)
