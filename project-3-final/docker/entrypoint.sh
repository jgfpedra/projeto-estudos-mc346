#!/usr/bin/env bash
# entrypoint.sh — roda o backend Guile e depois o renderer Python
set -e

cd /fractal/guile

echo "=== FractalDSL: gerando pontos com Guile ==="
guile --no-auto-compile -c "(load \"fractal-reader.scm\") (run-frac-file \"/fractal/ilha.frac\")"

echo ""
echo "=== Renderizando imagens com Python ==="

python3 /fractal/python/render_fractal.py \
    ilha.csv /fractal/output/ilha.png \
    --color teal --bg "#020d14" --dpi 200

echo ""
echo "=== Pronto! Imagens em /fractal/output/ ==="
ls -lh /fractal/output/
