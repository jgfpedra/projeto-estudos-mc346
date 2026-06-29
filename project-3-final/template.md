# DSL `FractalDSL`

## Descrição Resumida da DSL

FractalDSL é uma linguagem de domínio específico embutida em **Guile/Scheme** para descrever e renderizar fractais de forma declarativa. O usuário descreve um fractal através de primitivas compostas em pipeline funcional — sem laços explícitos, sem arrays, sem estado mutável — e a linguagem cuida de toda a matemática subjacente.

A motivação é tornar fractais acessíveis: alguém que não conhece os coeficientes de uma transformação afim ou a lógica de escape-time do Mandelbrot consegue, ainda assim, compor formas complexas ajustando parâmetros de alto nível (`roughness`, `depth`, `zoom`). A DSL oferece três modos de geração — Sistemas de Funções Iteradas (IFS), escape-time (Mandelbrot/Julia) e costa por deslocamento de ponto médio — com um renderer Python que produz imagens PNG.

A relevância está na demonstração de que Lisp/Scheme é excepcionalmente natural para DSLs: a homoiconicidade, os macros higiênicos e a avaliação sob demanda permitem construir uma linguagem nova dentro da linguagem hospedeira com muito pouco código de plumbing.

## Slides

> *[(link para o PDF da apresentação final —](https://docs.google.com/presentation/d/1i06y_mGzuyqCypy4Dji0fu_97srXgSgDr73D-7HfJCs/edit?usp=sharing) *

## Sintaxe da Linguagem

A FractalDSL tem duas camadas de sintaxe.

### Camada externa: arquivos `.frac`

Sintaxe baseada em indentação, inspirada em Python/YAML. Um arquivo `.frac` contém três tipos de bloco de nível zero:

#### `fractal` — define um fractal

```
fractal <Nome>
    iterations <N>
    <bloco de modo>
```

**Modo coastline** (costa por deslocamento de ponto médio):

```
fractal Ilha
    iterations 10000
    coastline
        points    7       # vértices do polígono inicial
        radius    1.0     # raio circunscrito
        roughness 0.4     # amplitude de deslocamento (0 = suave)
        depth     6       # níveis de subdivisão
        decorate          # opcional: decoração IFS em cada aresta
            steps  80     # iterações do caos por semente
            scale  0.06   # escala da nuvem IFS
            transform 0.85
                depth 4
                barnsley
                    affine 0.85  0.04 -0.04  0.85  0.0  1.60
```

**Modo equation** (escape-time, Mandelbrot/Julia):

```
fractal Mandelbrot
    equation   z=z^2+c   # formas suportadas: z^n+c, z^n-c, z^n, z*z+c
    iterations 150
    center     -0.5 0    # centro no plano complexo
    zoom       100        # half-width = 200/zoom
    resolution 800 800
```

**Modo IFS** (jogo do caos):

```
fractal Sierpinski
    iterations 50000
    ifs
        transform 0.33
            sierpinski
                affine 0.5 0.0 0.0 0.5 0.0 0.0
        transform 0.33
            barnsley
                affine 0.5 0.0 0.0 0.5 0.5 0.0
```

Os coeficientes de `affine` seguem a transformação: `x' = a·x + b·y + e`, `y' = c·x + d·y + f`
(7 valores: `a b c d e f g` onde `g` é o deslocamento vertical extra para o Barnsley Fern).

#### `render` — configurações de saída

```
render
    resolution 1200 1200
    color mono            # green | ocean | fire | teal | limegreen | mono | gradient
    style island          # island | forest | mountain | cloud
```

Escrito em `render.cfg`; consumido pelo renderer Python via `entrypoint.sh`.

#### `generate` — dispara a exportação

```
generate <Nome>    # gera <nome>.csv com os pontos do fractal
```

---

### Camada interna: primitivas Scheme

A DSL externa compila para chamadas Scheme. O mesmo fractal pode ser escrito diretamente:

```scheme
; Pipeline funcional — cada primitiva devolve um novo fractal (imutável)
(define mandelbrot
  (zoom
    (center
      (iterations
        (equation (create-fractal "Mandelbrot") "z=z^2+c")
        150)
      -0.5 0)
    100))

(export-csv mandelbrot "mandelbrot.csv")
```

```scheme
; IFS com composição via with-depth
(define ilha
  (iterations
    (ifs (create-fractal "Ilha")
      (transform 0.85 (with-depth 4 barnsley))
      (transform 0.07 (with-depth 4 barnsley))
      (transform 0.07 (with-depth 4 barnsley))
      (transform 0.01 (with-depth 4 barnsley)))
    10000))
```

`(with-depth d f)` expande o sub-fractal `f` por `d` níveis antes de cada ponto ser amostrado — fractais como valores de primeira classe dentro de outros fractais.

## Gramática da Linguagem

Gramática EBNF para a camada `.frac`. Indentação é significativa: um bloco filho tem recuo estritamente maior que o pai.

```ebnf
program        ::= statement+
statement      ::= fractal-block | render-block | generate-stmt

fractal-block  ::= "fractal" NAME NEWLINE INDENT+ fractal-body
fractal-body   ::= iterations-stmt? mode-block
iterations-stmt ::= "iterations" INTEGER NEWLINE

mode-block     ::= coastline-block | equation-block | ifs-block

(* ── Coastline ── *)
coastline-block ::= "coastline" NEWLINE INDENT+ coastline-param+
coastline-param ::= ("points"    INTEGER
                   | "radius"    FLOAT
                   | "roughness" FLOAT
                   | "depth"     INTEGER
                   | decorate-block) NEWLINE
decorate-block ::= "decorate" NEWLINE INDENT+ decorate-param+
decorate-param ::= ("steps" INTEGER | "scale" FLOAT | transform-stmt) NEWLINE
transform-stmt ::= "transform" FLOAT NEWLINE INDENT+ transform-body
transform-body ::= ("depth" INTEGER NEWLINE)? ifs-named
ifs-named      ::= ("barnsley" | "sierpinski") NEWLINE INDENT+ affine-stmt+
affine-stmt    ::= "affine" FLOAT FLOAT FLOAT FLOAT FLOAT FLOAT FLOAT NEWLINE

(* ── Equation (escape-time) ── *)
equation-block ::= "equation" EXPR NEWLINE equation-param*
equation-param ::= ("iterations" INTEGER
                   | "center"     FLOAT FLOAT
                   | "zoom"       FLOAT
                   | "resolution" INTEGER INTEGER) NEWLINE
EXPR           ::= "z=" ("z^" INTEGER ("+c" | "-c")? | "z*z+c")

(* ── Render ── *)
render-block   ::= "render" NEWLINE INDENT+ render-param+
render-param   ::= ("resolution" INTEGER INTEGER
                   | "color"      PALETTE
                   | "style"      STYLE) NEWLINE
PALETTE        ::= "green" | "ocean" | "fire" | "teal" | "limegreen" | "mono" | "gradient"
STYLE          ::= "island" | "forest" | "mountain" | "cloud"

(* ── Generate ── *)
generate-stmt  ::= "generate" NAME NEWLINE

(* ── Terminais ── *)
NAME           ::= [A-Za-z][A-Za-z0-9_]*
INTEGER        ::= [0-9]+
FLOAT          ::= "-"? [0-9]+ ("." [0-9]+)?
NEWLINE        ::= "\n"
INDENT         ::= " "+   (* nível determinado por contagem de espaços *)
```

O formalismo é **EBNF** (Extended Backus-Naur Form). Indentação não é capturada formalmente aqui — o parser em `fractal-reader.scm` usa a contagem de espaços iniciais de cada linha para construir a árvore hierárquica.

## Notebook

[macros-abstraction.ipynb](macros-abstraction.ipynb) — notebook do professor demonstrando o uso de macros Guile (`define-macro` e `define-syntax`) para construir primitivas SQL-like, servindo de referência para o estilo de abstração empregado na FractalDSL.

O código-fonte da DSL está em `guile/` (backend Scheme) e `python/` (renderer). Instruções completas de execução no README.md.

## Exemplos Selecionados

Todos os exemplos abaixo são executados com:

```bash
cd project-3-final/guile
guile --no-auto-compile -c '(load "fractal-reader.scm") (run-frac-file "../<arquivo>.frac")'
python ../python/render_fractal.py <nome>.csv <nome>.png --style <estilo>
```

### 1. Ilha (`ilha.frac`) — coastline + IFS decoration

Polígono de 7 vértices, 6 níveis de subdivisão, decorado com Barnsley Fern (vegetação).

```
fractal Ilha
    iterations 10000
    coastline
        points 7 · radius 1.0 · roughness 0.4 · depth 6
        decorate (steps 80 · scale 0.06 · barnsley fern 4-deep)
render: 1200×1200 · color mono · style island
```

**Resultado:** polígono costeiro irregular com nuvem de pontos (vegetação) clipada ao interior.

### 2. Floresta (`floresta.frac`) — costa mais densa

Mesma estrutura que a ilha, mas com `points 9`, `roughness 0.55` (costa mais recortada) e `steps 120` (vegetação mais densa). Estilo `forest` preenche o interior com verde escuro e sem outline.

### 3. Montanha (`montanha.frac`) — estilo mountain

`roughness 0.6`, `style mountain` — paleta monocromática cinza, terra preenchida em pedra.

### 4. England (`england.frac`) — contorno real simplificado

Costa com `points 12`, `roughness 0.3` (menos aleatório), aproximando um contorno geográfico real.

### 5. Mandelbrot (`mandelbrot.frac`) — escape-time

```
fractal Mandelbrot
    equation z=z^2+c · iterations 150 · center -0.5 0 · zoom 100 · resolution 800 800
render: 1600×1600 · color green
```

Grid de escape-time: cada pixel colorido pelo número de iterações até `|z| > 2`. Pixels que nunca escapam (conjunto de Mandelbrot) forçados a preto.

## Discussão

A proposta inicial era criar uma DSL declarativa para fractais que abstraísse a matemática de baixo nível. O resultado alcança isso em três dimensões:

**Abstração funcional:** A camada Scheme interna é um pipeline puramente funcional — cada primitiva (`equation`, `iterations`, `center`, `zoom`, `ifs`, `with-depth`) recebe um fractal (alist imutável) e devolve um novo, sem efeitos colaterais. Isso torna a composição direta e testável.

**Abstração sintática:** A camada `.frac` eleva ainda mais o nível de abstração, escondendo os parens e a estrutura de alist atrás de uma sintaxe indentada próxima de configuração. O parser (`fractal-reader.scm`) compila esses blocos para Scheme e `eval`ua — uma forma de macro-expansão textual.

**Separação de concerns:** A decisão de separar geração de dados (Guile/Scheme) de renderização (Python/matplotlib) permitiu que cada componente evoluísse independentemente. Adicionar uma nova paleta de cores não requer tocar no código Scheme; adicionar um novo modo de geração não requer tocar no Python.

O maior desafio foi o parser de indentação: Scheme não tem suporte nativo a sintaxe sensível a whitespace, então foi necessário implementar a lógica de `direct-children` manualmente com contagem de espaços. A ausência de um framework como ANTLR limitou a expressividade da gramática externa.

Um ponto de melhoria identificado: a camada Scheme expõe `ifs` e `with-depth` como funções regulares (`define`), quando poderiam ser macros verdadeiras (`define-syntax`), permitindo sintaxe mais natural sem aspas explícitas e com higiene garantida pelo compilador.

## Conclusão

**Principais conclusões:**
- Scheme/Guile é uma plataforma excelente para eDSLs: a homoiconicidade permite que a DSL interna seja indistinguível da linguagem hospedeira.
- Pipelines funcionais imutáveis simplificam radicalmente o raciocínio sobre composição de fractais.
- A separação geração/renderização em linguagens diferentes (Scheme + Python) é uma arquitetura limpa, mas exige uma camada de serialização (CSV) que adiciona I/O.

**Principais desafios:**
- Implementar um parser de indentação sem biblioteca de suporte em Scheme.
- Fazer o `with-depth` funcionar corretamente com uma pilha explícita para evitar recursão infinita no jogo do caos.
- Integrar a geração estocástica (coastline usa `random-real`) de forma reproduzível (ausência de seed fixo ainda é uma limitação).

**Lições aprendidas:**
- Começar com a eDSL Scheme e só depois adicionar a camada `.frac` foi a ordem certa — a camada externa emergiu naturalmente como açúcar sintático sobre algo que já funcionava.
- `eval` em Scheme é poderoso mas dificulta diagnóstico de erros (mensagens de erro apontam para o código gerado, não para o `.frac` original).

# Trabalhos Futuros

- **Macros higiênicas:** Reescrever `ifs`, `with-depth` e `transform` usando `define-syntax` para eliminar a necessidade de quotar argumentos manualmente na camada Scheme.
- **Seed reproduzível:** Adicionar suporte a `seed <N>` no bloco `coastline` e no IFS para tornar os resultados determinísticos.
- **Coloração por escape-time suavizada:** Implementar smooth coloring (interpolação fracionária) no Mandelbrot em vez de bandas discretas.
- **Julia sets:** A equação `z=z^2+c` com `c` fixo já funciona matematicamente; falta expor `c` como parâmetro no bloco `equation`.
- **Mais formas geométricas iniciais:** A `coastline` começa sempre de um polígono regular; permitir formas iniciais customizadas (e.g., retângulo, espiral).
- **Renderer nativo em Scheme:** Eliminar a dependência de Python usando uma biblioteca de imagens Guile (e.g., `guile-cairo`) para o pipeline completo em uma só linguagem.

# Referências Bibliográficas

- Barnsley, M. F. (1988). *Fractals Everywhere*. Academic Press.
- Mandelbrot, B. B. (1982). *The Fractal Geometry of Nature*. W. H. Freeman.
- Dybvig, R. K. (2003). *The Scheme Programming Language* (4ª ed.). MIT Press. Disponível em: https://www.scheme.com/tspl4/
- SRFI-27: Sources of Random Bits. https://srfi.schemers.org/srfi-27/
- Documentação do Guile Scheme: https://www.gnu.org/software/guile/manual/
- Documentação do Matplotlib (renderer Python): https://matplotlib.org/
