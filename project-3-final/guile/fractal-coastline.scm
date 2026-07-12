(load "fractal-core.scm")
(load "fractal-ifs.scm")

(use-modules (srfi srfi-27))   ; random-real
(random-source-randomize! default-random-source) 

(define (midpoint a b)
  (list (/ (+ (car a)  (car b))  2.0)
        (/ (+ (cadr a) (cadr b)) 2.0)))

(define (perpendicular-displace a b amount)
  (let* ((dx (- (car b)  (car a)))
         (dy (- (cadr b) (cadr a)))
         (len (sqrt (+ (* dx dx) (* dy dy))))
         (nx (/ (- dy) len))   ; rotate 90°
         (ny (/ dx len)))
    (list (* nx amount) (* ny amount))))

(define (displace-midpoint a b roughness)
  (let* ((dx       (- (car b)  (car a)))
         (dy       (- (cadr b) (cadr a)))
         (edge-len (sqrt (+ (* dx dx) (* dy dy))))
         (mid      (midpoint a b))
         (disp     (* roughness edge-len (- (random-real) 0.5) 2.0))
         (perp     (perpendicular-displace a b disp)))
    (list (+ (car mid)  (car perp))
          (+ (cadr mid) (cadr perp)))))

(define (regular-polygon n radius)
  (map (lambda (i)
         (let ((angle (* 2.0 3.14159265 (/ i n))))
           (list (* radius (cos angle))
                 (* radius (sin angle)))))
       (iota n)))

(define (elliptical-polygon n radius-x radius-y)
  (map (lambda (i)
         (let ((angle (* 2.0 3.14159265 (/ i n))))
           (list (* radius-x (cos angle))
                 (* radius-y (sin angle)))))
       (iota n)))

(define (subdivide-once polygon roughness)
  (let loop ((pts polygon) (acc '()))
    (if (null? pts)
        (reverse acc)
        (let* ((a   (car pts))
               (b   (if (null? (cdr pts)) (car polygon) (cadr pts)))
               (mid (displace-midpoint a b roughness)))
          (loop (cdr pts) (cons mid (cons a acc)))))))

(define (subdivide-polygon polygon roughness depth)
  (if (= depth 0)
      polygon
      (subdivide-polygon (subdivide-once polygon roughness)
                         roughness
                         (- depth 1))))

(define %generate-cache (make-hash-table))

(define (generate-cached fractal)
  (let ((name (get-field fractal 'name)))
    (or (hash-ref %generate-cache name #f)
        (let ((result (generate fractal)))
          (hash-set! %generate-cache name result)
          result))))

(define (take-n lst n)
  (let loop ((lst lst) (n n) (acc '()))
    (if (or (null? lst) (= n 0))
        (reverse acc)
        (loop (cdr lst) (- n 1) (cons (car lst) acc)))))

(define (choose-and-run-source sources)
  (let* ((total (apply + (map car sources)))
         (r     (* (random-real) total)))
    (let loop ((ss sources) (acc 0))
      (let* ((s       (car ss))
             (new-acc (+ acc (car s))))
        (if (or (>= new-acc r) (null? (cdr ss)))
            ((cdr s))
            (loop (cdr ss) new-acc))))))

(define (points-of fractal-result)
  (if (and (pair? fractal-result) (pair? (car fractal-result)) (list? (caar fractal-result)))
      (append (car fractal-result) (cdr fractal-result))
      fractal-result))

(define (build-cloud-sources transforms steps-per-seed fractal-refs)
  (append
    (if (null? transforms)
        '()
        (list (cons 1.0 (lambda () (run-ifs-local transforms steps-per-seed)))))
    (map (lambda (ref)
           (cons (car ref)
                 (lambda ()
                   (take-n
                     (map (lambda (p) (list (car p) (cadr p)))
                          (points-of (generate-cached (cdr ref))))
                     steps-per-seed))))
         fractal-refs)))

(define (resolve-fractal-refs refs)
  (map (lambda (r) (cons (car r) (eval (string->symbol (cdr r)) (interaction-environment))))
       refs))

(define (generate-coastline points radius-x radius-y roughness depth)
  (subdivide-polygon (elliptical-polygon points radius-x radius-y) roughness depth))

(define (run-cloud source n)
  (if (and (pair? source) (pair? (car source)) (equal? (caar source) 'transform))
      (iterate-ifs-from source n)
      (take-n
        (map (lambda (p) (list (car p) (cadr p)))
             (points-of (generate-cached source)))
        n)))

(define (run-ifs-local transforms n)
  (iterate-ifs-from transforms n))

(define (anchor-cloud cloud seed-x seed-y scale)
  (map (lambda (p)
         (list (+ seed-x (* scale (car p)))
               (+ seed-y (* scale (cadr p)))))
       cloud))

(define (decorate-coastline polygon transforms steps-per-seed scale fractal-refs)
  (let ((sources (build-cloud-sources transforms steps-per-seed fractal-refs)))
    (let loop ((pts polygon) (acc '()))
      (if (or (null? pts) (null? (cdr pts)))
          acc
          (let* ((a       (car pts))
                 (b       (cadr pts))
                 (seed-x  (/ (+ (car a)  (car b))  2.0))
                 (seed-y  (/ (+ (cadr a) (cadr b)) 2.0))
                 (cloud   (choose-and-run-source sources))
                 (placed  (anchor-cloud cloud seed-x seed-y scale)))
            (loop (cdr pts) (append placed acc)))))))

(define (polygon-centroid polygon)
  (let ((n (length polygon)))
    (list (/ (apply + (map car  polygon)) n)
          (/ (apply + (map cadr polygon)) n))))

(define (polygon-avg-radius polygon center)
  (let* ((cx (car center)) (cy (cadr center)))
    (/ (apply + (map (lambda (p)
                        (sqrt (+ (expt (- (car p) cx) 2)
                                 (expt (- (cadr p) cy) 2))))
                      polygon))
       (length polygon))))

(define (decorate-interior polygon transforms steps-per-seed scale n radius-fraction fractal-refs)
  (let* ((center  (polygon-centroid polygon))
         (cx      (car center))
         (cy      (cadr center))
         (avg-r   (polygon-avg-radius polygon center))
         (sources (build-cloud-sources transforms steps-per-seed fractal-refs)))
    (let loop ((i 0) (acc '()))
      (if (= i n)
          acc
          (let* ((angle  (* 2.0 3.14159265 (/ (+ i 0.5) n)))
                 (seed-x (+ cx (* radius-fraction avg-r (cos angle))))
                 (seed-y (+ cy (* radius-fraction avg-r (sin angle))))
                 (cloud  (choose-and-run-source sources))
                 (placed (anchor-cloud cloud seed-x seed-y scale)))
            (loop (+ i 1) (append placed acc)))))))

(define (generate-island params)
  (let* ((rx        (let ((v (assq 'radius-x params))) (and v (cdr v))))
         (ry        (let ((v (assq 'radius-y params))) (and v (cdr v))))
         (r         (let ((v (assq 'radius   params))) (and v (cdr v))))
         (radius-x  (or rx r 1.0))
         (radius-y  (or ry r 1.0))
         (points    (cdr (assq 'points    params)))
         (roughness (cdr (assq 'roughness params)))
         (depth     (cdr (assq 'depth     params)))
         (decor     (assq 'decorate params))
         (coast     (generate-coastline points radius-x radius-y roughness depth)))
    (if decor
        (let* ((d            (cdr decor))
               (transforms   (cdr (assq 'transforms d)))
               (steps        (cdr (assq 'steps      d)))
               (scale        (cdr (assq 'scale      d)))
               (raw-refs     (let ((r (assq 'fractal-refs d))) (if r (cdr r) '())))
               (fractal-refs (resolve-fractal-refs raw-refs))
               (edge-decor   (decorate-coastline coast transforms steps scale fractal-refs))
               (fill-n       (let ((f (assq 'fill d))) (and f (cdr f))))
               (fill-decor
                 (if (and fill-n (> fill-n 0))
                     (let* ((get (lambda (key default)
                                   (let ((v (assq key d))) (if (and v (cdr v)) (cdr v) default))))
                            (fill-scale  (get 'fill-scale  scale))
                            (fill-steps  (get 'fill-steps  steps))
                            (fill-radius (get 'fill-radius 0.5)))
                       (decorate-interior coast transforms fill-steps fill-scale
                                          fill-n fill-radius fractal-refs))
                     '())))
          (cons coast (append edge-decor fill-decor)))
        coast)))

(define (make-island name iterations points radius-x radius-y roughness depth
                      decoration steps scale)
  (make-filled-island name iterations points radius-x radius-y roughness depth
                       decoration steps scale #f scale steps 0.5 '()))

(define (make-filled-island name iterations points radius-x radius-y roughness depth
                             decoration steps scale
                             fill fill-scale fill-steps fill-radius
                             fractal-refs)
  (fractal-pipe (create-fractal name)
    (set-field 'iterations iterations)
    (set-field 'coastline
      (list (cons 'points     points)
            (cons 'radius-x   radius-x)
            (cons 'radius-y   radius-y)
            (cons 'roughness  roughness)
            (cons 'depth      depth)
            (cons 'decorate
                  (list (cons 'steps        steps)
                        (cons 'scale        scale)
                        (cons 'fill         fill)
                        (cons 'fill-scale   fill-scale)
                        (cons 'fill-steps   fill-steps)
                        (cons 'fill-radius  fill-radius)
                        (cons 'transforms   decoration)
                        (cons 'fractal-refs fractal-refs)))))))
