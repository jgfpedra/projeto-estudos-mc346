;;; fractal-coastline.scm — midpoint-displacement coastline generator + IFS boundary decoration
(load "fractal-core.scm")
(load "fractal-ifs.scm")

(use-modules (srfi srfi-27))   ; random-real
(random-source-randomize! default-random-source) 

;; ─── Helpers ──────────────────────────────────────────────────────────────

(define (midpoint a b)
  (list (/ (+ (car a)  (car b))  2.0)
        (/ (+ (cadr a) (cadr b)) 2.0)))

(define (perpendicular-displace a b amount)
  ;; unit vector perpendicular to (b - a), scaled by amount
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

;; ─── Coastline generation ─────────────────────────────────────────────────

;; Build initial regular polygon with N vertices around the origin
(define (regular-polygon n radius)
  (map (lambda (i)
         (let ((angle (* 2.0 3.14159265 (/ i n))))
           (list (* radius (cos angle))
                 (* radius (sin angle)))))
       (iota n)))

;; One level of midpoint-displacement on a closed polygon
(define (subdivide-once polygon roughness)
  (let loop ((pts polygon) (acc '()))
    (if (null? pts)
        (reverse acc)
        (let* ((a   (car pts))
               (b   (if (null? (cdr pts)) (car polygon) (cadr pts)))
               (mid (displace-midpoint a b roughness)))
          (loop (cdr pts) (cons mid (cons a acc)))))))

;; Recursively subdivide for `depth` levels
(define (subdivide-polygon polygon roughness depth)
  (if (= depth 0)
      polygon
      (subdivide-polygon (subdivide-once polygon roughness)
                         roughness
                         (- depth 1))))

;; Full coastline polygon
(define (generate-coastline points radius roughness depth)
  (subdivide-polygon (regular-polygon points radius) roughness depth))

;; ─── IFS decoration ───────────────────────────────────────────────────────

;; Run the IFS chaos game from the origin for n steps (local attractor shape)
(define (run-ifs-local transforms n)
  (iterate-ifs-from transforms n))

;; Translate + uniformly scale a point cloud to sit at (seed-x, seed-y)
(define (anchor-cloud cloud seed-x seed-y scale)
  (map (lambda (p)
         (list (+ seed-x (* scale (car p)))
               (+ seed-y (* scale (cadr p)))))
       cloud))

;; Stamp a scaled IFS cloud at the midpoint of every polygon edge
(define (decorate-coastline polygon transforms steps-per-seed scale)
  (let loop ((pts polygon) (acc '()))
    (if (or (null? pts) (null? (cdr pts)))
        acc
        (let* ((a       (car pts))
               (b       (cadr pts))
               (seed-x  (/ (+ (car a)  (car b))  2.0))
               (seed-y  (/ (+ (cadr a) (cadr b)) 2.0))
               (cloud   (run-ifs-local transforms steps-per-seed))
               (placed  (anchor-cloud cloud seed-x seed-y scale)))
          (loop (cdr pts) (append placed acc))))))

;; ─── Entry point ─────────────────────────────────────────────────────────

;; Returns: (coast-points . decor-points) or just coast-points if no decoration
(define (generate-island params)
  (let* ((points    (cdr (assq 'points    params)))
         (radius    (cdr (assq 'radius    params)))
         (roughness (cdr (assq 'roughness params)))
         (depth     (cdr (assq 'depth     params)))
         (decor     (assq 'decorate params))
         (coast     (generate-coastline points radius roughness depth)))
    (if decor
        (let* ((d          (cdr decor))
               (transforms (cdr (assq 'transforms d)))
               (steps      (cdr (assq 'steps      d)))
               (scale      (cdr (assq 'scale      d)))
               (decoration (decorate-coastline coast transforms steps scale)))
          (cons coast decoration))
        coast)))
