#!/usr/bin/env bash
# entrypoint.sh — roda o backend Guile e depois o renderer Python
set -e

cd /fractal/guile

echo "=== FractalDSL: gerando pontos com Guile ==="
guile --no-auto-compile -l examples.scm

echo ""
echo "=== Renderizando imagens com Python ==="

python3 /fractal/python/render_fractal.py \
    sierpinski.csv /fractal/output/sierpinski.png \
    --color green --bg "#040a04" --dpi 200

python3 /fractal/python/render_fractal.py \
    barnsley.csv /fractal/output/barnsley.png \
    --color limegreen --bg "#030a02" --dpi 200

python3 /fractal/python/render_fractal.py \
    ilha.csv /fractal/output/ilha.png \
    --color teal --bg "#020d14" --dpi 200

echo ""
echo "=== Pronto! Imagens em /fractal/output/ ==="
ls -lh /fractal/output/
