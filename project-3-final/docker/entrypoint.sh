#!/usr/bin/env bash
set -e

FRAC_DIR="${FRAC_DIR:-/fractal/frac}"

if [ ! -d "$FRAC_DIR" ] || [ -z "$(ls -A "$FRAC_DIR"/*.frac 2>/dev/null)" ]; then
    echo "ERRO: nenhum .frac encontrado em '$FRAC_DIR'."
    echo "Copie seus arquivos .frac para essa pasta (Dockerfile) ou monte-a via volume."
    exit 1
fi

cd /fractal/guile
mkdir -p /fractal/output

# Limpa CSV/PNG que possam ter vindo junto no COPY do build (evita confundir
# resultado antigo com resultado desta execução).
rm -f ./*.csv ./*.png

for frac_file in "$FRAC_DIR"/*.frac; do
    name="$(basename "$frac_file" .frac)"
    echo ""
    echo "=== [$name] ==="
    # fractal-reader.scm já cuida de tudo por .frac: parse, export CSV e
    # render PNG (via `generate`, que chama render_fractal.py internamente).
    guile --no-auto-compile -c "(load \"fractal-reader.scm\") (run-frac-file \"${frac_file}\")"
done

echo ""
echo "=== Copiando PNGs para /fractal/output ==="
shopt -s nullglob
pngs=(./*.png)
if [ ${#pngs[@]} -eq 0 ]; then
    echo "  (nenhum PNG foi gerado — confira se seus .frac têm bloco 'generate')"
else
    cp -v "${pngs[@]}" /fractal/output/
fi

echo ""
echo "=== Pronto! Imagens em /fractal/output/ ==="
ls -lh /fractal/output/
