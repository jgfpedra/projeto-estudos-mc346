;;; fractal-reader.scm — parser de indentação para FractalDSL
(load "fractal-core.scm")
(load "fractal-params.scm")
(load "fractal-generate.scm")
(load "fractal-ifs.scm")

(use-modules (ice-9 rdelim)
             (srfi srfi-1))

;; ─── leitura de linhas ────────────────────────────────────────────────────

(define (read-lines filename)
  (call-with-input-file filename
    (lambda (port)
      (let loop ((acc '()))
        (let ((line (read-line port)))
          (if (eof-object? line)
              (reverse acc)
              (loop (cons line acc))))))))

(define (indent-of line)
  (let loop ((cs (string->list line)) (n 0))
    (if (and (pair? cs) (char=? (car cs) #\space))
        (loop (cdr cs) (+ n 1))
        n)))

(define (tokens-of line)
  (filter (lambda (s) (not (string=? s "")))
          (string-split (string-trim-both line) #\space)))

(define (to-indexed lines)
  (filter (lambda (x) (pair? (cdr x)))
          (map (lambda (l)
                 (cons (indent-of l) (tokens-of l)))
               lines)))

;; ─── extrai filhos diretos de um nível ───────────────────────────────────

(define (direct-children nodes parent-indent)
  ;; pega só nós com indent > parent-indent,
  ;; parando quando volta ao mesmo nível ou menor
  (let ((child-indent #f))
    (let loop ((ns nodes) (acc '()))
      (if (null? ns)
          (reverse acc)
          (let* ((n   (car ns))
                 (ind (car n)))
            (cond
              ((and (not child-indent) (> ind parent-indent))
               (set! child-indent ind)
               (loop (cdr ns) (cons n acc)))
              ((and child-indent (>= ind child-indent))
               (loop (cdr ns) (cons n acc)))
              (else
               (reverse acc))))))))

(define (siblings-after nodes parent-indent)
  (let loop ((ns nodes))
    (if (null? ns)
        '()
        (if (<= (car (car ns)) parent-indent)
            ns
            (loop (cdr ns))))))

;; ─── build de affine ─────────────────────────────────────────────────────

(define (build-affine-node node)
  ;; node: (indent "affine" weight a b c d e f)
  (let ((nums (map string->number (cddr node))))
    `(transform ,(car nums) (affine ,@(cdr nums)))))

;; ─── build de ifs (sierpinski ou barnsley) ───────────────────────────────

(define (build-ifs-node node all-nodes)
  (let* ((name  (cadr node))
         (fname (cond ((equal? name "sierpinski") "Sierpinski")
                      ((equal? name "barnsley")   "BarnsleyFern")
                      (else name)))
         (ind      (car node))
         (children (direct-children all-nodes ind))
         (affines  (filter (lambda (c) (equal? (cadr c) "affine")) children)))
    `(ifs (create-fractal ,fname)
       ,@(map build-affine-node affines))))

;; ─── build de transform ──────────────────────────────────────────────────

(define (build-transform-node node all-nodes)
  ;; node: (indent "transform" prob)
  (let* ((prob     (string->number (caddr node)))
         (ind      (car node))
         (children (direct-children all-nodes ind))
         (depth-node  (find (lambda (c) (equal? (cadr c) "depth")) children))
         (depth    (if depth-node
                       (string->number (caddr depth-node))
                       #f))
         (sub-node (find (lambda (c)
                           (or (equal? (cadr c) "sierpinski")
                               (equal? (cadr c) "barnsley")))
                         children))
         (ifs-expr (build-ifs-node sub-node all-nodes)))
    (if depth
        `(transform ,prob (with-depth ,depth ,ifs-expr))
        `(transform ,prob ,ifs-expr))))

;; ─── build de fractal ─────────────────────────────────────────────────────

(define (build-fractal name all-nodes)
  (let* ((iter-node (find (lambda (n) (equal? (cadr n) "iterations")) all-nodes))
         (iters     (if iter-node (string->number (caddr iter-node)) 10000))
         (ifs-node  (find (lambda (n) (equal? (cadr n) "ifs")) all-nodes))
         (ifs-ind   (car ifs-node))
         (t-nodes   (filter (lambda (n)
                              (and (equal? (cadr n) "transform")
                                   (> (car n) ifs-ind)))
                            all-nodes))
         (transforms (map (lambda (t)
                            (build-transform-node t all-nodes))
                          t-nodes)))
    `(define ,(string->symbol name)
       (let* ((f (create-fractal ,name))
              (f (set-field f 'iterations ,iters))
              (f (set-field f 'ifs (list ,@transforms))))
         f))))

;; ─── entry point ─────────────────────────────────────────────────────────

(define (run-frac-file filename)
  (let* ((lines   (read-lines filename))
         (indexed (to-indexed lines))
         (top     (filter (lambda (n) (= (car n) 0)) indexed)))

    (for-each
      (lambda (node)
        (let ((kw (cadr node)))
          (cond

            ((equal? kw "fractal")
             (let* ((name     (caddr node))
                    (children (direct-children (cdr (member node indexed)) 0))
                    (expr     (build-fractal name children)))
               (display "Compilando: ") (display name) (newline)
               (display expr) (newline)
               (eval expr (the-environment))))

            ((equal? kw "generate")
             (let* ((name (caddr node))
                    (sym  (string->symbol name))
                    (csv  (string-append name ".csv")))
               (display "Exportando: ") (display csv) (newline)
               (export-csv (eval sym (the-environment)) csv))))))
      top)))
