# FractalDSL

DSL embutida em **Guile/Scheme** para descrever fractais, com renderer em Python que gera imagens PNG.

```
FractalDSL/
├── guile/
│   ├── fractal-core.scm      # estrutura de dados + aritmética complexa
│   ├── fractal-params.scm    # primitivas: equation, constant, iterations, center, zoom…
│   ├── fractal-ifs.scm       # IFS: affine, transform, (ifs …), (with-depth d f)
│   ├── fractal-generate.scm  # parser de equação + generate + export-csv
│   └── examples.scm          # Mandelbrot, Julia, Sierpinski, Barnsley, Ilha
├── python/
│   └── render_fractal.py     # CSV → PNG com density coloring
└── docker/
    ├── Dockerfile
    ├── docker-compose.yml
    └── entrypoint.sh
```

---
 
## Rodando com Docker (recomendado)

### Pré-requisito
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) ou Docker Engine + Compose instalado.

### 1 — Build e run completo
```bash
# da raiz do projeto:
cd docker
mkdir -p output
docker compose up --build
```

As imagens aparecem em `docker/output/`.

### 2 — Shell interativo dentro do container
```bash
docker compose run --entrypoint bash fractaldsl
# dentro do container:
cd /fractal/guile
guile --no-auto-compile
# REPL Guile — carregue os módulos:
# (load "fractal-generate.scm")
# (load "fractal-params.scm")
```

### 3 — Só o renderer Python
```bash
docker compose run --entrypoint python3 fractaldsl \
    /fractal/python/render_fractal.py \
    /fractal/guile/ilha.csv \
    /fractal/output/ilha.png \
    --color teal --bg "#020d14"
```

---

## Rodando localmente (sem Docker)

### Guile
```bash
# Ubuntu/Debian
sudo apt install guile-3.0

# macOS (Homebrew)
brew install guile

# Gera os CSVs:
cd guile
guile --no-auto-compile -l examples.scm
```

### Python
```bash
pip install numpy matplotlib

python render_fractal.py sierpinski.csv sierpinski.png --color green
python render_fractal.py barnsley.csv   barnsley.png   --color limegreen
python render_fractal.py ilha.csv       ilha.png       --color teal --bg "#0a1a2f"
```

---

## Como a DSL funciona

### Primitivas de configuração
```scheme
(define mandelbrot
  (zoom
    (center
      (iterations
        (equation (create-fractal "Mandelbrot") "z=z^2+c")
        500)
      -0.5 0)
    200))

(generate mandelbrot)   ; → número de iterações até escape
```

### IFS com macros
```scheme
(define sierpinski
  (iterations
    (ifs (create-fractal "Sierpinski")
      (transform 0.33 (affine 0.5 0.0 0.0 0.5 0.0  0.0))
      (transform 0.33 (affine 0.5 0.0 0.0 0.5 0.5  0.0))
      (transform 0.34 (affine 0.5 0.0 0.0 0.5 0.25 0.5)))
    50000))
```

### Composição com `with-depth`
```scheme
(define ilha
  (iterations
    (ifs (create-fractal "Ilha")
      (transform 0.5 (with-depth 12 sierpinski-base))   ; litoral recortado
      (transform 0.5 (with-depth  8 barnsley-base)))    ; vegetação interior
    20000))
```

`(with-depth d f)` é uma **macro** que expande `f` por `d` níveis de recursão antes de cada ponto ser amostrado pelo IFS pai — isso permite que fractais sejam valores de primeira classe dentro de outros fractais.

### Exportando para Python
```scheme
(export-csv ilha "ilha.csv")
```

---

## Opções do renderer

| flag | padrão | descrição |
|---|---|---|
| `--color` | `mono` | paleta: `green`, `ocean`, `fire`, `teal`, `limegreen`, `mono` |
| `--bg` | `#000000` | cor de fundo (hex) |
| `--dpi` | `300` | resolução do PNG |
| `--size` | `2048` | largura/altura em pixels |
| `--alpha` | `0.6` | transparência do mapa de densidade |
| `--pt` | `0.3` | tamanho do ponto no scatter overlay |

---

## Próximos passos sugeridos

- **Coloração por escape time** no Mandelbrot/Julia (atualmente só conta iterações).
- **IFS estocástico com seed fixo** para reprodutibilidade.
- **Noise fractal (Perlin + IFS)** para terreno de ilha mais orgânico.
- **Clojure port**: substituir `define-macro` por `defmacro` do Clojure e usar `defrecord` para a estrutura do fractal.
