;;; fractal-dsl-reader.scm — macros que implementam a sintaxe da FractalDSL
(load "fractal-core.scm")
(load "fractal-params.scm")
(load "fractal-generate.scm")
(load "fractal-ifs.scm")

;; ─── fractal Name { ... } ─────────────────────────────────────────────────
;; Uso: (fractal Mandelbrot (equation "z=z^2+c") (iterations 500) ...)
(define-macro (fractal name . body)
  `(define ,(string->symbol (symbol->string name))
     (let* ((f (create-fractal ,(symbol->string name)))
            ,@(map (lambda (stmt)
                     (list 'f stmt))
                   body))
       (fold-left (lambda (acc stmt) stmt) f (list ,@body)))))

;; ─── Melhor abordagem: pipeline funcional via thread-first ────────────────
;; cada primitiva recebe e devolve o fractal

(define-macro (fractal name . body)
  `(define ,(string->symbol (symbol->string name))
     (let ((f (create-fractal ,(symbol->string name))))
       (apply-params f (list ,@body)))))

(define (apply-params f params)
  (if (null? params)
      f
      (apply-params ((car params) f) (cdr params))))

;; ─── Primitivas retornam funções f→f ─────────────────────────────────────

(define-macro (dsl-equation expr-str)
  `(lambda (f) (set-field f 'equation ,expr-str)))

(define-macro (dsl-iterations n)
  `(lambda (f) (set-field f 'iterations ,n)))

(define-macro (dsl-center re im)
  `(lambda (f) (set-field f 'center (list ,re ,im))))

(define-macro (dsl-zoom z)
  `(lambda (f) (set-field f 'zoom ,z)))

(define-macro (dsl-constant name val)
  `(lambda (f)
     (let ((cs (get-field f 'constants)))
       (set-field f 'constants
         (cons (cons ',name ,val)
               (if (eq? cs #nil) '() cs))))))

;; ─── IFS via DSL ──────────────────────────────────────────────────────────

(define-macro (dsl-ifs . transforms)
  `(lambda (f) (set-field f 'ifs (list ,@transforms))))

;; ─── generate ─────────────────────────────────────────────────────────────

(define-macro (generate name)
  `(export-csv ,name ,(string-append (symbol->string 'name) ".csv")))

;; ─── render (por enquanto só registra, Python cuida disso) ───────────────

(define-macro (render name . opts)
  `(begin
     (display "render: ") (display ,(symbol->string 'name)) (newline)))
