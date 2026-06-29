# Comparação de DSLs para Fractais

Este documento compara a **FractalDSL** com outras linguagens e ferramentas voltadas à geração de fractais, destacando diferenças de paradigma, capacidade de composição e integração com a linguagem hospedeira.

---

## Ferramentas comparadas

| Ferramenta | Tipo | Paradigma | Linguagem base |
|---|---|---|---|
| **FractalDSL** (este projeto) | eDSL embutida | Funcional declarativo | Guile/Scheme |
| **Context Free Art (CFDG)** | DSL externa | Gramática stocástica | Nenhuma |
| **L-Systems** | Formalismo + bibliotecas | Gramática de substituição | Depende da lib |
| **Apophysis / Flam3** | Ferramenta GUI + XML | IFS interativo | XML |
| **Ultra Fractal** | Software comercial | Fórmulas imperativas | UF Script |
| **p5.js / Processing** | Biblioteca | Imperativo | JavaScript / Java |

---

## Comparação detalhada

### 1. Paradigma e sintaxe

**FractalDSL** oferece duas camadas: uma DSL externa baseada em indentação (`.frac`) e primitivas Scheme encadeáveis em pipeline funcional. A imutabilidade é central — cada operação devolve um novo fractal.

```
; FractalDSL — pipeline funcional
(zoom (center (iterations (equation (create-fractal "M") "z=z^2+c") 150) -0.5 0) 100)

; ou com .frac
fractal Mandelbrot
    equation z=z^2+c
    iterations 150
    center -0.5 0
    zoom 100
```

**Context Free Art (CFDG)** usa regras de substituição com probabilidade, inspiradas em gramáticas livres de contexto. Focado em arte 2D geométrica, não em fractais matemáticos clássicos.

```cfdg
startshape TREE

rule TREE {
  CIRCLE { }
  TREE { y 1 size 0.9 rotate 5 }
}
```

**L-Systems** descrevem crescimento vegetal como substituições de símbolos seguidas de interpretação por tartaruga (turtle graphics). Naturalmente recursivos, mas limitados a traçado de linhas.

```
axiom: F
F → F[+F]F[-F]F
```

**Apophysis / Flam3** usa matrizes XML para definir sistemas IFS com efeito de chama. O usuário edita parâmetros via GUI; não há linguagem de programação no loop.

**Ultra Fractal** permite escrever fórmulas de iteração em UF Script (imperativo), mas sem composição, macros ou capacidade de abstração além de parâmetros numéricos.

**p5.js / Processing** é uma biblioteca para canvas; o usuário escreve loops explícitos. Máxima flexibilidade, mínima abstração para fractais.

---

### 2. Tipos de fractal suportados

| Tipo | FractalDSL | CFDG | L-Systems | Flam3 | Ultra Fractal | p5.js |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| IFS (Barnsley, Sierpinski) | ✓ | — | — | ✓ | — | manual |
| Escape-time (Mandelbrot, Julia) | ✓ | — | — | — | ✓ | manual |
| Coastline / terreno fractal | ✓ | — | — | — | — | manual |
| Arte geométrica recursiva | — | ✓ | ✓ | — | — | manual |
| Fractais de chama (IFS estocástico colorido) | parcial | — | — | ✓ | — | manual |

FractalDSL é a única que integra os três modos (IFS, escape-time, coastline) em um único pipeline com a mesma estrutura de dados.

---

### 3. Composição e abstração

Este é o ponto mais diferenciador da FractalDSL.

**FractalDSL — `with-depth`:** um fractal pode ser usado como sub-transformação de outro, expandido recursivamente pelo motor de jogo do caos. Fractais são valores de primeira classe.

```scheme
; IFS cujas ramificações são outros fractais inteiros
(ifs (create-fractal "Composto")
  (transform 0.5 (with-depth 4 sierpinski))
  (transform 0.5 (with-depth 3 barnsley)))
```

**CFDG** tem composição via regras nomeadas, mas sem passagem de fractais como valores. A recursão é implícita na gramática, não programável.

**L-Systems** têm substituição de símbolos, mas a composição é rígida — não se pode parametrizar a "profundidade" de um sub-sistema em tempo de execução.

**Flam3 / Apophysis** têm parâmetros de mistura entre transformações, mas não composição de sub-fractais como valores.

**Ultra Fractal / p5.js** não têm mecanismo de composição — o usuário implementa manualmente.

---

### 4. Macros e metaprogramação

A maior vantagem do Scheme como linguagem hospedeira é o sistema de macros.

| Ferramenta | Macros / metaprog | Tipo |
|---|---|---|
| **FractalDSL** | ✓ (`define-syntax`, `define-macro`) | Higiênicas (Scheme R7RS) |
| **CFDG** | — | N/A |
| **L-Systems** | — | N/A |
| **Flam3** | — | XML |
| **Ultra Fractal** | — | N/A |
| **p5.js** | parcial | JavaScript (sem macros) |

Com `define-syntax` em Scheme, é possível criar literais de sintaxe (`from`, `where`, `as`) dentro da DSL sem modificar o parser — algo impossível em ferramentas baseadas em GUI ou XML.

---

### 5. Renderização

| Ferramenta | Renderização | Controle de paleta | Saída |
|---|---|---|---|
| **FractalDSL** | Python/matplotlib (via subprocess) | 7 paletas, estilos, bg customizável | PNG |
| **CFDG** | Nativa (C++/OpenGL) | Sim | PNG, SVG |
| **L-Systems** | Biblioteca (turtle, tkinter, etc.) | Depende da lib | Depende |
| **Flam3** | Nativa (C, multi-thread) | Alta (HDR, gamma, etc.) | PNG, EXR |
| **Ultra Fractal** | Nativa (OpenGL, GPU) | Alta | PNG, TIFF |
| **p5.js** | Canvas do browser | Total (CSS + JS) | PNG, SVG |

FractalDSL é a única que separa completamente geração de dados (Scheme) de renderização (Python), o que facilita trocar o backend de renderização sem alterar a DSL.

---

### 6. Curva de aprendizado e extensibilidade

| Ferramenta | Para usar | Para estender |
|---|---|---|
| **FractalDSL** | Baixa (`.frac` é simples) | Alta (Scheme como linguagem hospedeira) |
| **CFDG** | Baixa (gramática simples) | Baixa (linguagem fechada) |
| **L-Systems** | Média (axiomas + regras) | Baixa (formalismo fixo) |
| **Flam3** | Baixa (GUI) | Muito baixa (XML + C source) |
| **Ultra Fractal** | Média | Baixa (UF Script limitado) |
| **p5.js** | Alta (JS imperativo) | Alta (JS completo) |

---

## Resumo

FractalDSL ocupa um nicho específico: é a única ferramenta que trata **fractais como valores de primeira classe em um pipeline funcional**, permitindo composição com `with-depth`, múltiplos modos de geração (IFS, escape-time, coastline) e extensão via macros Scheme. O custo é a dependência de Guile e Python no pipeline.

CFDG é a alternativa mais próxima em espírito (declarativo, estocástico), mas limitada a arte 2D geométrica sem suporte a escape-time. L-Systems são superiores para modelagem vegetal/orgânica via turtle graphics. Flam3/Ultra Fractal são superiores em qualidade de renderização, mas fechados a extensão programática.

---

## Referências

- CFDG (Context Free Design Grammar): https://contextfreeart.org/
- Lindenmayer, A.; Prusinkiewicz, P. (1990). *The Algorithmic Beauty of Plants*. Springer.
- Draves, S. (2003). *The Fractal Flame Algorithm*. https://flam3.com/flame_draves.pdf
- Ultra Fractal: https://www.ultrafractal.com/
- p5.js: https://p5js.org/
