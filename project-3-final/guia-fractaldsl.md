# Guia de uso — FractalDSL

Este guia mostra como escrever um `.frac` do zero: fractais de equação (Mandelbrot/Julia), fractais IFS (Sierpinski/Barnsley), fractais de costa (coastline), como decorar e como compor fractais entre si.

Pra instalação e pipeline (Docker/local), ver `doc.md`. Aqui o foco é só a linguagem.

---

## 1. Estrutura geral de um `.frac`

Um arquivo tem, em qualquer ordem, no nível 0 (sem indentação):

```
define decoration <Nome>   # opcional, reutilizável
define style <Nome>        # opcional, reutilizável
fractal <Nome>              # um ou mais
render                      # config de saída
generate <Nome>             # um ou mais, dispara a geração
```

A indentação é o que define hierarquia — não tem parênteses. Cada nível de indentação (múltiplo de 4 espaços, por convenção) é filho do nível anterior.

Todo `fractal` precisa escolher **um** dos três modos: `equation`, `ifs`, ou `coastline`.

---

## 2. Fractais de equação (Mandelbrot / Julia)

Modo escape-time: itera `z → f(z, c)` por pixel até estourar `|z| > 2` ou bater `iterations`.

```
fractal Mandelbrot
    equation z=z^2+c
    iterations 200
    center -0.5 0.0
    zoom 150

render
    resolution 800 800
    color fire
    style cloud

generate Mandelbrot
```

**Campos:**
- `equation` — precisa do formato `z=<expressão>`, com o `z=` na frente (o parser corta no `=` e usa só o lado direito). Expressões reconhecidas hoje: `z^n+c`, `z^n-c`, `z^n` (troque `n` por um inteiro), e `z*z+c`.
- `iterations` — máximo de iterações por pixel.
- `center` — `<re> <im>` do centro da imagem no plano complexo.
- `zoom` — quanto maior, mais "zoom in".
- `constant c <re> <im>` (opcional) — se declarado, o fractal vira **Julia** (c fixo, z0 = pixel); se omitido, é **Mandelbrot** (c = pixel, z0 = 0).

**Julia:**
```
fractal Julia
    equation z=z^2+c
    iterations 100
    center 0.0 0.0
    zoom 150
    constant c -0.7 0.27015

render
    resolution 800 800
    color ocean
    style cloud

generate Julia
```

> `style` do render só aceita `island`, `forest`, `mountain`, `cloud` — pra fractal de equação use sempre `cloud`.

> Resolução alta (800×800) com muitas iterações é lento (Scheme interpretado, sem otimização de ponto flutuante). Pra testar rápido, use `resolution 200 200` e `iterations 50`, só suba os valores depois de validar.

---

## 3. Fractais IFS (Sierpinski / Barnsley)

Modo *chaos game*: em cada passo, sorteia uma transformação afim (por probabilidade) e aplica no ponto atual.

```
fractal Sierpinski
    iterations 50000
    ifs
        transform 0.33
            depth 1
            sierpinski
                affine 1.0  0.5 0.0 0.0 0.5 0.0  0.0
        transform 0.33
            depth 1
            sierpinski
                affine 1.0  0.5 0.0 0.0 0.5 0.5  0.0
        transform 0.34
            depth 1
            sierpinski
                affine 1.0  0.5 0.0 0.0 0.5 0.25 0.5

render
    resolution 800 800
    color mono
    style cloud

generate Sierpinski
```

**Estrutura de cada `transform`:**
```
transform <probabilidade>
    depth <N>
    <sierpinski | barnsley>
        affine <prob-interna> <a> <b> <c> <d> <e> <f>
```

- `<probabilidade>` — peso de escolha desse `transform` no sorteio geral (as probabilidades de todos os `transform` de um `ifs` devem somar ~1.0).
- `depth` — **obrigatório**. Cada `transform` nomeado (`sierpinski`/`barnsley` + `affine`) vira, internamente, um sub-fractal IFS de um nível; `depth` diz quantos passos desse sub-fractal rodam de uma vez antes de voltar pro nível de fora. Pra chaos game clássico (um passo por seleção), use `depth 1`. Valores maiores (`depth 3-5`) fazem sentido em decorações (seção 4), onde cada âncora gera vários pontos numa "explosão" local.
- `<sierpinski | barnsley>` — só o nome do branch; não muda o comportamento, é rótulo.
- `affine <prob-interna> a b c d e f` — **7 números**, não 6. O primeiro é a probabilidade interna do sub-fractal (irrelevante se só há um `affine` no branch — use `1.0`); os 6 seguintes são os coeficientes da transformação afim: `x' = a·x + b·y + e`, `y' = c·x + d·y + f`.

**Barnsley fern:**
```
fractal BarnsleyFern
    iterations 100000
    ifs
        transform 0.85
            depth 1
            barnsley
                affine 1.0  0.85  0.04 -0.04  0.85  0.0  1.60
        transform 0.07
            depth 1
            barnsley
                affine 1.0  0.20 -0.26  0.23  0.22  0.0  1.60
        transform 0.07
            depth 1
            barnsley
                affine 1.0  -0.15  0.28  0.26  0.24  0.0  0.44
        transform 0.01
            depth 1
            barnsley
                affine 1.0  0.0   0.0   0.0   0.16  0.0  0.0

render
    resolution 800 800
    color forest
    style cloud

generate BarnsleyFern
```

---

## 4. Fractais de costa (coastline)

Gera um polígono e subdivide as arestas com deslocamento aleatório de ponto médio (midpoint displacement), criando uma linha de costa irregular.

```
fractal Ilha
    iterations 10000
    coastline
        points 8
        radius 1.0
        roughness 0.35
        depth 6

render
    resolution 1200 1200
    color ocean
    style island

generate Ilha
```

**Campos de `coastline`:**
- `points` — número de vértices do polígono base.
- `radius` — raio do polígono base.
- `roughness` — quanto de deslocamento aleatório em cada subdivisão (0 = liso, valores maiores = mais irregular).
- `depth` — quantas vezes o polígono é subdividido (cada subdivisão dobra o número de vértices).

`iterations` aqui não é usado pela geração de costa em si — só é lido se o fractal também tivesse modo equation (não é o caso). Pode manter como valor de referência.

`style island` no render é o padrão certo pra esse modo (existe também `forest`, `mountain`, `cloud`).

### `define style` — reaproveitar parâmetros de coastline

```
define style IlhaBase
    points 8
    radius 1.0
    roughness 0.35
    depth 6

fractal Ilha
    iterations 10000
    coastline
        extends IlhaBase
```

`extends <Nome>` herda `points`/`radius`/`roughness`/`depth` do style; qualquer um desses campos declarado localmente sobrescreve o do style.

---

## 5. Decoração (`decorate`)

Espalha "nuvens" de pontos (geradas por um IFS) ancoradas ao longo da borda da costa — pra simular vegetação, textura, etc.

```
define decoration Vegetacao
    steps 90
    scale 0.06
    transform 0.85
        depth 4
        barnsley
            affine 1.0  0.85  0.04 -0.04  0.85  0.0  1.60
    transform 0.15
        depth 4
        barnsley
            affine 1.0  0.20 -0.26  0.23  0.22  0.0  1.60

fractal Ilhota
    iterations 10000
    coastline
        points 10
        radius 1.0
        roughness 0.22
        depth 6
        decorate
            use Vegetacao

render
    resolution 1200 1200
    color ocean
    style island

generate Ilhota
```

**Campos de `decorate`:**
- `use <Nome>` — traz `steps`, `scale` e os `transform` de uma `define decoration`. `steps`/`scale` declarados localmente junto de `use` sobrescrevem os da decoração base; os `transform` em si não têm merge (pra mudar as afins, precisa de uma nova `define decoration`).
- `steps` — quantos pontos o IFS da decoração gera por âncora na borda.
- `scale` — fator de escala da nuvem de pontos ao redor de cada âncora.
- `fill <N>` (opcional) — além de decorar a borda, espalha `N` âncoras adicionais no **interior** do polígono.
- `fill-scale`, `fill-steps`, `fill-radius` (opcionais) — mesma ideia de `scale`/`steps`, mas pro preenchimento interior; `fill-radius` é a fração do raio médio da ilha onde as âncoras internas ficam (0 = centro, 1 = borda).

---

## 6. Composição entre fractais (`use-fractal`)

Além de decorar com IFS puro, dá pra usar **outro fractal já definido** (island, IFS, o que for) como fonte de pontos de decoração — ele é gerado inteiro e uma amostra dos pontos é ancorada.

```
fractal IlhaPequena
    iterations 5000
    coastline
        points 6
        radius 0.5
        roughness 0.4
        depth 5

fractal IlhaGrande
    iterations 8000
    coastline
        points 8
        radius 1.0
        roughness 0.35
        depth 6
        decorate
            use-fractal IlhaPequena 1.0
            steps 40
            scale 0.25

render
    resolution 1000 1000
    color ocean
    style island

generate IlhaPequena
generate IlhaGrande
```

`use-fractal <Nome> <peso>` — `<peso>` é a chance desse fractal ser escolhido como fonte, toda vez que uma âncora é decorada (comparado aos outros `use`/`use-fractal` do mesmo `decorate`; não precisa somar exatamente 1.0, é peso relativo).

Pode combinar `use` (decoração IFS) e `use-fractal` (outro fractal) no mesmo `decorate`, e usar mais de um `use-fractal`.

**Cuidados ao encadear fractais:**
- O fractal referenciado é gerado uma única vez e reaproveitado (cache), então encadear (A → B usa A → C usa B) não recalcula do zero a cada âncora.
- Ainda assim, cada `use-fractal` usa só uma amostra de `steps` pontos por âncora — não a ilha inteira.
- Evite encadear ilhas que já têm `fill` grande como fonte de outras com `fill` grande — o resultado (não o tempo) cresce rápido nesse caso, porque cada nível soma o tamanho já decorado do anterior.

---

## 7. Bloco `render`

```
render
    resolution <W> <H>
    color <paleta>
    style <estilo>
```

- `resolution` — tamanho da imagem final em pixels.
- `color` — `green` `ocean` `fire` `teal` `limegreen` `mono` `gradient`.
- `style` — `island` `forest` `mountain` `cloud`. Use `island`/`forest`/`mountain` pra coastline (dependendo do efeito visual desejado), e `cloud` pra qualquer coisa que não seja um polígono fechado (equation, IFS puro).

Um `.frac` só precisa de um bloco `render`, aplicado a todos os `generate` que vierem depois dele no arquivo.

---

## 8. Bloco `generate`

```
generate <Nome>
```

Dispara a geração de fato: exporta `<nome-minúsculo>.csv` e chama o renderer pra produzir `<nome-minúsculo>.png`, usando a config do `render` mais recente no arquivo.

Pode ter vários `generate` no mesmo arquivo — útil quando um fractal é `use-fractal` de outro e você quer ver as duas imagens.

---

## 9. Referência

| Modo | Campos obrigatórios | Campos opcionais |
|---|---|---|
| `equation` | `equation`, `iterations`, `center`, `zoom` | `constant c <re> <im>` (vira Julia) |
| `ifs` | `iterations`, `ifs` com um ou mais `transform` | — |
| `coastline` | `points`, `radius`, `roughness`, `depth` (ou `extends <style>`) | `decorate` (`use`, `use-fractal`, `steps`, `scale`, `fill`, `fill-scale`, `fill-steps`, `fill-radius`) |

---

## 10. Erros comuns

- **`equation` sem `z=` na frente** → quebra o parser (`cadr` de lista vazia). Sempre `equation z=z^2+c`, nunca `equation z^2+c`.
- **`style equation` ou `style ifs` no render** → renderer só aceita `island`/`forest`/`mountain`/`cloud`. Use `cloud` pra equation e ifs puro.
- **`affine` com 6 números em vez de 7** → falta a probabilidade interna na frente (`affine <prob> a b c d e f`).
- **`transform` sem `depth`** → obrigatório sempre que o transform usa um branch nomeado (`sierpinski`/`barnsley` + `affine`).
- **`transform` no mesmo nível de indentação do `ifs`** → precisa estar um nível mais indentado (filho do `ifs`, não irmão).
- **Encadear `use-fractal` de ilhas já decoradas com `fill` grande** → cresce rápido; prefira referenciar ilhas simples (sem decoração própria) quando possível.
