(load "fractal-generate.scm")

(define (find-renderer)
  (cond ((file-exists? "../python/render_fractal.py")
         "../python/render_fractal.py")
        ((file-exists? "/fractal/python/render_fractal.py")
         "/fractal/python/render_fractal.py")
        (else "../python/render_fractal.py")))

(define (read-render-cfg-key key default)
  (if (not (file-exists? "render.cfg"))
      default
      (call-with-input-file "render.cfg"
        (lambda (port)
          (let loop ()
            (let ((line (read-line port)))
              (cond
                ((eof-object? line) default)
                ((string-prefix? (string-append key "=") line)
                 (substring line (+ (string-length key) 1)))
                (else (loop)))))))))

(define (render-csv-and-png! csv-path png-path)
  (let ((width  (read-render-cfg-key "WIDTH" "800"))
        (height (read-render-cfg-key "HEIGHT" "800"))
        (color  (read-render-cfg-key "COLOR" "mono"))
        (style  (read-render-cfg-key "STYLE" "island")))
    (display (string-append "Renderizando: " png-path)) (newline)
    (system* "python3" (find-renderer) csv-path png-path
             "--style" style "--color" color
             "--width" width "--height" height)
    png-path))

(define (render-png! fractal png-path)
  (let* ((name     (string-downcase (get-field fractal 'name)))
         (csv-path (string-append name ".csv")))
    (display (string-append "Exportando CSV: " csv-path)) (newline)
    (export-csv fractal csv-path)
    (render-csv-and-png! csv-path png-path)
    (display "PNG gerado.") (newline)
    png-path))

(define (generate-fractal style-thunk)
  (let* ((f    (style-thunk))
         (name (string-downcase (get-field f 'name)))
         (csv  (string-append name ".csv"))
         (png  (string-append name ".png")))
    (export-csv f csv)
    (display (string-append "Exportando: " csv)) (newline)
    (render-csv-and-png! csv png)
    (display "PNG gerado.") (newline)
    f))
