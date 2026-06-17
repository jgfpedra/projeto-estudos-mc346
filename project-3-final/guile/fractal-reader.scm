;;; fractal-reader.scm — parser de indentação para FractalDSL
(load "fractal-core.scm")
(load "fractal-params.scm")
(load "fractal-generate.scm")
(load "fractal-ifs.scm")
(load "fractal-coastline.scm")

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
         (rest     (cdr (member node all-nodes eq?)))  ; everything after this node
         (children (direct-children rest ind))
         (affines  (filter (lambda (c) (equal? (cadr c) "affine")) children)))
    `(ifs (create-fractal ,fname)
       ,@(map build-affine-node affines))))

;; ─── build de transform ──────────────────────────────────────────────────

(define (build-transform-node node all-nodes)
  ;; node: (indent "transform" prob)
  (let* ((prob     (string->number (caddr node)))
         (ind      (car node))
         (children (direct-children (cdr (member node all-nodes eq?)) ind))
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


;; ─── build render-node ─────────────────────────────────────────────────────

(define (build-render-node node all-nodes)
  (let* ((ind        (car node))
         (children   (direct-children (cdr (member node all-nodes eq?)) ind))
         (res-node   (find (lambda (c) (equal? (cadr c) "resolution")) children))
         (color-node (find (lambda (c) (equal? (cadr c) "color")) children))
         (width      (if res-node (string->number (caddr res-node)) 800))
         (height     (if res-node (string->number (cadddr res-node)) 800))
         (color      (if color-node (caddr color-node) "mono")))
    (list (cons 'width width) (cons 'height height) (cons 'color color))))

(define (get-field-alist alist key)
  (let ((r (assq key alist))) (if r (cdr r) #f)))

(define (write-render-config render-cfg out-path)
  (call-with-output-file out-path
    (lambda (port)
      (display "WIDTH=" port)
      (display (get-field-alist render-cfg 'width) port)
      (newline port)
      (display "HEIGHT=" port)
      (display (get-field-alist render-cfg 'height) port)
      (newline port)
      (display "COLOR=" port)
      (display (get-field-alist render-cfg 'color) port)
      (newline port))))

(define (build-decorate-node node all-nodes)
  (let* ((ind        (car node))
         (children   (direct-children (cdr (member node all-nodes eq?)) ind))
         (steps-node (find (lambda (c) (equal? (cadr c) "steps")) children))
         (scale-node (find (lambda (c) (equal? (cadr c) "scale")) children))
         (t-nodes    (filter (lambda (c) (equal? (cadr c) "transform")) children))
         (steps      (if steps-node (string->number (caddr steps-node)) 60))
         (scale      (if scale-node (string->number (caddr scale-node)) 0.06))
         (transforms (map (lambda (t) (build-transform-node t all-nodes)) t-nodes)))
    `((steps      . ,steps)
      (scale      . ,scale)
      (transforms . ,transforms))))   ; ← no (list ...) wrapper, just the raw list

(define (build-coastline-node name all-nodes)
  (let* ((coast-node  (find (lambda (n) (equal? (cadr n) "coastline")) all-nodes))
         (ind         (car coast-node))
         (children    (direct-children (cdr (member coast-node all-nodes eq?)) ind))
         (get-num     (lambda (key default)
                        (let ((n (find (lambda (c) (equal? (cadr c) key)) children)))
                          (if n (string->number (caddr n)) default))))
         (points      (get-num "points"    7))
         (radius      (get-num "radius"    1.0))
         (roughness   (get-num "roughness" 0.4))
         (depth       (get-num "depth"     6))
         (decor-node  (find (lambda (c) (equal? (cadr c) "decorate")) children))
         (iter-node   (find (lambda (n) (equal? (cadr n) "iterations")) all-nodes))
         (iters       (if iter-node (string->number (caddr iter-node)) 10000)))
    (if decor-node
        ;; Build the decorate alist at reader time and inject it as a literal
        (let* ((decor (build-decorate-node decor-node all-nodes))
               (steps      (cdr (assq 'steps      decor)))
               (scale      (cdr (assq 'scale      decor)))
               (transforms (cdr (assq 'transforms decor))))
          `(define ,(string->symbol name)
             (let* ((f (create-fractal ,name))
                    (f (set-field f 'iterations ,iters))
                    (f (set-field f 'coastline
                         (list (cons 'points     ,points)
                               (cons 'radius     ,radius)
                               (cons 'roughness  ,roughness)
                               (cons 'depth      ,depth)
                               (cons 'decorate
                                     (list (cons 'steps      ,steps)
                                           (cons 'scale      ,scale)
                                           (cons 'transforms (list ,@transforms))))))))
               f)))
        `(define ,(string->symbol name)
           (let* ((f (create-fractal ,name))
                  (f (set-field f 'iterations ,iters))
                  (f (set-field f 'coastline
                       (list (cons 'points    ,points)
                             (cons 'radius    ,radius)
                             (cons 'roughness ,roughness)
                             (cons 'depth     ,depth)))))
             f)))))
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
             (let* ((name          (caddr node))
                    (children      (direct-children (cdr (member node indexed eq?)) 0))
                    (has-coastline (find (lambda (n) (equal? (cadr n) "coastline")) children))
                    (expr          (if has-coastline
                                       (build-coastline-node name children)
                                       (build-fractal name children))))
               (display "Compilando: ") (display name) (newline)
               (display expr) (newline)
               (eval expr (interaction-environment))))
            ((equal? kw "render")
             (let* ((cfg      (build-render-node node indexed))
                    (cfg-path "render.cfg"))
               (display "Configurando render: ") (display cfg) (newline)
               (write-render-config cfg cfg-path)))
            ((equal? kw "generate")
             (let* ((name (caddr node))
                    (sym  (string->symbol name))
                    (csv  (string-append (string-downcase name) ".csv")))
               (display "Exportando: ") (display csv) (newline)
               (export-csv (eval sym (interaction-environment)) csv))))))
      top)))
