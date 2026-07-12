(use-modules (ice-9 rdelim) (srfi srfi-1))

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

(define (direct-children nodes parent-indent)
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

(define (shallow-children nodes parent-indent)
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
              ((and child-indent (= ind child-indent))
               (loop (cdr ns) (cons n acc)))
              ((and child-indent (> ind child-indent))
               (loop (cdr ns) acc))
              (else
               (reverse acc))))))))

(define (siblings-after nodes parent-indent)
  (let loop ((ns nodes))
    (if (null? ns)
        '()
        (if (<= (car (car ns)) parent-indent)
            ns
            (loop (cdr ns))))))

(define (extract-block full shallow key)
  (let ((node (find (lambda (n) (equal? (cadr n) key)) shallow)))
    (if (not node)
        '()
        (cons node (direct-children (cdr (member node full eq?)) (car node))))))
