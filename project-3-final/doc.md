# Como usar a FractalDSL

Duas formas de rodar: via **Docker** (recomendado, sem instalar nada) ou **localmente** com Guile + Python.

## 1. Via Docker (recomendado)

Pré-requisitos: Docker e Docker Compose instalados.

```bash
cd docker/
docker compose up --build
```

O que acontece:
1. `docker-compose.yml` builda a imagem a partir do `Dockerfile` (contexto é a raiz do projeto, `context: ..`).
2. O `Dockerfile` instala Guile + Python/matplotlib/numpy e copia `guile/`, `python/` e o arquivo `.frac` para dentro da imagem.
3. `entrypoint.sh` roda automaticamente ao subir o container: chama o Guile pra gerar o CSV do fractal, depois chama o `render_fractal.py` pra gerar o PNG.
4. O resultado aparece em `docker/output/` na sua máquina (montado via volume no `docker-compose.yml`, mapeado para `/fractal/output` dentro do container).

**Configuração de render:** o `entrypoint.sh` lê `WIDTH`, `HEIGHT`, `COLOR`, `STYLE` de um `render.cfg` na raiz (se existir), com defaults `800x800`, `mono`, `island`. Esse `render.cfg` normalmente é gerado pelo bloco `render` do próprio `.frac` (via `write-render-config` em `fractal-reader.scm`), então na prática não precisa editar nada manualmente — só ajustar o bloco `render` no `.frac`.

> ⚠️ **Atenção:** hoje o `Dockerfile` copia `ilha.frac` para dentro da imagem, mas o `entrypoint.sh` está fixado para rodar `/fractal/floresta.frac`. Se for reproduzir o pipeline como está, garanta que o `.frac` copiado pelo `Dockerfile` tenha o mesmo nome do que o `entrypoint.sh` espera (ou edite um dos dois) — do contrário o build falha ao não achar o arquivo.

Pra rodar outro `.frac` sem editar o `Dockerfile`, a forma mais simples é editar a linha do `guile -c` em `entrypoint.sh` apontando pro arquivo desejado, ou montar seu próprio `.frac` via volume adicional no `docker-compose.yml`.

## 2. Localmente (sem Docker)

Pré-requisitos: `guile` e `python3` com `numpy`/`matplotlib` instalados.

```bash
cd guile/
guile --no-auto-compile -c '(load "fractal-reader.scm") (run-frac-file "../seu-arquivo.frac")'
python3 ../python/render_fractal.py <nome>.csv <nome>.png --style <estilo>
```

- `run-frac-file` interpreta o `.frac`, gera `<nome>.csv` (pontos do fractal) e `render.cfg` (config de render, se houver bloco `render`).
- O `render_fractal.py` lê o CSV e produz o PNG final. Parâmetros: `--style` (`island`/`forest`/`mountain`/`cloud`), `--color` (`green`/`ocean`/`fire`/`teal`/`limegreen`/`mono`/`gradient`), `--width`/`--height`/`--dpi`.

## 3. Sintaxe rápida de `.frac`

Um arquivo `.frac` pode ter, em qualquer ordem no nível 0: blocos `define`, `fractal`, `render`, `generate`.

```
fractal <Nome>
    iterations <N>
    <coastline | equation | ifs>   # um dos três modos

render
    resolution <W> <H>
    color <paleta>
    style <estilo>

generate <Nome>
```

Ver `README.md` na raiz do projeto para a gramática completa (EBNF) e exemplos comentados de cada modo (coastline, equation/escape-time, ifs).

## 4. Decorações reutilizáveis (`define decoration` / `use`)

Pra evitar repetir o mesmo bloco de decoração IFS (ex.: a mesma vegetação Barnsley) em vários fractais, dá pra nomear e reutilizar:

```
define decoration Vegetacao
    steps 90
    scale 0.06
    transform 0.85
        depth 4
        barnsley
            affine 0.85  0.85  0.04 -0.04  0.85  0.0  1.60
    transform 0.07
        depth 4
        barnsley
            affine 0.07  0.20 -0.26  0.23  0.22  0.0  1.60
    transform 0.07
        depth 4
        barnsley
            affine 0.07 -0.15  0.28  0.26  0.24  0.0  0.44
    transform 0.01
        depth 4
        barnsley
            affine 0.01  0.0   0.0   0.0   0.16  0.0  0.0

fractal Ilhota
    iterations 10000
    coastline
        points 10
        radius 1.0
        roughness 0.22
        depth 6
        decorate
            use Vegetacao

fractal Floresta
    iterations 10000
    coastline
        points 9
        radius 1.0
        roughness 0.55
        depth 5
        decorate
            use Vegetacao
            steps 120     # sobrescreve o steps da decoração base
            scale 0.09    # sobrescreve o scale da decoração base
```

Regras:
- `define decoration <Nome>` deve estar no nível 0 do arquivo (mesmo nível de `fractal`/`render`/`generate`), em qualquer posição — é resolvido num passe prévio antes dos fractais serem processados, então pode vir antes ou depois de quem o usa.
- Dentro de `decorate`, `use <Nome>` traz `steps`, `scale` e todos os `transform` da decoração nomeada.
- `steps` e/ou `scale` declarados no `decorate` local, junto com `use`, sobrescrevem os valores da decoração base (útil pra variar densidade/escala da vegetação sem duplicar os `transform`).
- Os `transform` em si (as afins do IFS) não têm merge — vêm inteiros da decoração base. Pra variar as transformações, ainda é necessário escrever um novo `define decoration`.

Essa resolução acontece inteiramente no parser (`fractal-reader.scm`); nenhuma primitiva do backend Scheme (`fractal-core.scm`, `fractal-ifs.scm`, `fractal-coastline.scm`) precisa ser alterada.

## 5. Arquivos do projeto

| Arquivo | Papel |
|---|---|
| `fractal-core.scm` | estrutura de dados do fractal (alist) + aritmética complexa |
| `fractal-params.scm` | primitivas de parâmetro (`equation`, `iterations`, `center`, `zoom`, ...) |
| `fractal-ifs.scm` | primitivas de IFS (`affine`, `transform`, `ifs`, `with-depth`) + execução do jogo do caos |
| `fractal-coastline.scm` | geração de costa por deslocamento de ponto médio |
| `fractal-generate.scm` | exportação para CSV |
| `fractal-reader.scm` | parser de indentação do `.frac` → compila para chamadas Scheme e `eval`; também resolve `define decoration`/`use` |
| `render.cfg` | config de render lida pelo `entrypoint.sh` (gerada pelo bloco `render` do `.frac`) |
| `python/render_fractal.py` | renderer PNG (matplotlib) |
| `docker/Dockerfile`, `docker/docker-compose.yml`, `docker/entrypoint.sh` | pipeline containerizado |
