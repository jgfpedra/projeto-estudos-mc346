#!/usr/bin/env bash
WIDTH=800
HEIGHT=800
COLOR=mono
if [ -f render.cfg ]; then
    source render.cfg
fi
set -e
cd /fractal/guile
echo "=== FractalDSL: gerando pontos com Guile ==="
guile --no-auto-compile -c "(load \"fractal-reader.scm\") (run-frac-file \"/fractal/ilha.frac\")"
echo ""
echo "=== Renderizando imagens com Python ==="

python3 /fractal/python/render_fractal.py \
    ilha.csv /fractal/output/ilha.png \
    --color "limegreen" --width "$WIDTH" --height "$HEIGHT" --bg "#020d14" --dpi 2000

echo ""
echo "=== Pronto! Imagens em /fractal/output/ ==="
ls -lh /fractal/output/
