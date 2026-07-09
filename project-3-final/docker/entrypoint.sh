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

DEFAULT_WIDTH=800
DEFAULT_HEIGHT=800
DEFAULT_COLOR=mono
DEFAULT_STYLE=island

for frac_file in "$FRAC_DIR"/*.frac; do
    name="$(basename "$frac_file" .frac)"
    echo ""
    echo "=== [$name] gerando pontos com Guile ==="

    # cada .frac tem sua própria config de render — não deixar vazar a
    # config do arquivo anterior do loop.
    rm -f render.cfg
    WIDTH=$DEFAULT_WIDTH
    HEIGHT=$DEFAULT_HEIGHT
    COLOR=$DEFAULT_COLOR
    STYLE=$DEFAULT_STYLE

    # marca quais .csv já existem, pra saber depois o que este .frac gerou
    before="$(ls *.csv 2>/dev/null || true)"

    guile --no-auto-compile -c "(load \"fractal-reader.scm\") (run-frac-file \"${frac_file}\")"

    # config de render escrita pelo bloco `render` deste .frac (se houver)
    if [ -f render.cfg ]; then
        source render.cfg
    fi

    after="$(ls *.csv 2>/dev/null || true)"
    new_csvs="$(comm -13 <(echo "$before" | sort) <(echo "$after" | sort))"

    if [ -z "$new_csvs" ]; then
        echo "  (nenhum 'generate' encontrado em ${name}.frac -- nada pra renderizar)"
        continue
    fi

    echo "=== [$name] renderizando imagens com Python ==="
    while IFS= read -r csv; do
        [ -z "$csv" ] && continue
        base="${csv%.csv}"
        python3 /fractal/python/render_fractal.py \
            "$csv" "/fractal/output/${base}.png" \
            --style "$STYLE" --color "$COLOR" \
            --width "$WIDTH" --height "$HEIGHT" --dpi 2000
    done <<< "$new_csvs"
done

echo ""
echo "=== Pronto! Imagens em /fractal/output/ ==="
ls -lh /fractal/output/
