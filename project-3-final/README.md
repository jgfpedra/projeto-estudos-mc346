# FractalDSL

DSL embutida em **Guile/Scheme** para descrever fractais declarativamente, com renderer Python que gera imagens PNG.

```
project-3-final/
├── *.frac                    # arquivos de entrada (ilha, floresta, montanha, england, mandelbrot)
├── guile/
│   ├── fractal-reader.scm    # entry point: parser .frac + run-frac-file + render-png!
│   ├── fractal-core.scm      # estrutura de dados (alist) + aritmética complexa
│   ├── fractal-params.scm    # primitivas: equation, iterations, center, zoom…
│   ├── fractal-ifs.scm       # IFS: affine, transform, (ifs …), (with-depth d f)
│   ├── fractal-coastline.scm # modo coastline: midpoint displacement + decoração IFS
│   └── fractal-generate.scm  # parser de equação + generate + export-csv
├── python/
│   └── render_fractal.py     # CSV → PNG
├── docker/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── entrypoint.sh
├── fractal-examples.ipynb    # notebook com exemplos interativos
└── dsl-comparison.md         # comparação com CFDG, L-Systems, Flam3, Ultra Fractal, p5.js
```

---

## Rodando com Docker (recomendado)

```bash
cd docker
mkdir -p output
docker compose up --build   # gera ilha.png em docker/output/
```

Para outros fractais, edite `entrypoint.sh` trocando o nome do `.frac` e adicione o `COPY` correspondente no `Dockerfile`.

Shell interativo dentro do container:
```bash
docker compose run --entrypoint bash fractaldsl
```

---

## Rodando localmente

### Pré-requisitos
```bash
brew install guile          # macOS
sudo apt install guile-3.0  # Ubuntu/Debian

pip3 install numpy matplotlib
```

### Execução via arquivo `.frac`
```bash
cd project-3-final/guile
guile --no-auto-compile -c '(load "fractal-reader.scm") (run-frac-file "../ilha.frac")'
```

Se o `.frac` contiver um bloco `render`, o PNG é gerado automaticamente. Caso contrário, renderize manualmente:
```bash
python3 ../python/render_fractal.py ilha.csv ilha.png --style island --color mono
```

### Notebook interativo
```bash
cd project-3-final
python3 -m jupyter lab
# abrir fractal-examples.ipynb
```

---

## Sintaxe `.frac`

Três blocos de nível zero, com indentação significativa:

```
fractal Mandelbrot
    equation   z=z^2+c    # escape-time
    iterations 150
    center     -0.5 0
    zoom       100
    resolution 800 800

fractal Ilha
    iterations 10000
    coastline              # midpoint displacement
        points    7
        radius    1.0
        roughness 0.4
        depth     6
        decorate           # decoração IFS em cada aresta
            steps 80
            scale 0.06
            transform 0.85
                depth 4
                barnsley
                    affine 0.85 0.04 -0.04 0.85 0.0 1.60

render
    resolution 1200 1200
    color mono             # green | ocean | fire | teal | limegreen | mono | gradient
    style island           # island | forest | mountain | cloud

generate Mandelbrot        # exporta mandelbrot.csv e (se houver render) mandelbrot.png
```

---

## Primitivas Scheme

A camada `.frac` compila para Scheme puro. O mesmo fractal pode ser escrito diretamente:

```scheme
; pipeline funcional — cada primitiva devolve um novo fractal (imutável)
(define mandelbrot
  (zoom (center (iterations (equation (create-fractal "Mandelbrot") "z=z^2+c") 150) -0.5 0) 100))

(export-csv mandelbrot "mandelbrot.csv")

; ou direto para PNG (lê configurações de render.cfg se existir)
(render-png! mandelbrot "mandelbrot.png")
```

```scheme
; IFS com composição via with-depth
(ifs (create-fractal "Ilha")
  (transform 0.85 (with-depth 4 barnsley))
  (transform 0.07 (with-depth 4 barnsley)))
```

`(with-depth d f)` expande o sub-fractal `f` por `d` níveis antes de cada ponto ser amostrado — fractais como valores de primeira classe dentro de outros fractais.

---

## Opções do renderer

| flag | descrição |
|---|---|
| `--style` | `island`, `forest`, `mountain`, `cloud` — controla preenchimento e contorno (só coastline) |
| `--color` | paleta: `green`, `ocean`, `fire`, `teal`, `limegreen`, `mono`, `gradient` |
| `--bg` | cor de fundo em hex (ex: `#020d14`) |
| `--width` / `--height` | dimensão do PNG em pixels |
| `--dpi` | resolução (padrão: 300) |
| `--alpha` | transparência da nuvem de densidade (0.0–1.0) |
| `--pt` | tamanho do ponto no scatter |
