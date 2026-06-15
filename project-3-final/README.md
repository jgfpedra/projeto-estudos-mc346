# DSL `FractalDSL`

## Descrição Resumida da DSL

Fractais são objetos geométricos gerados pela aplicação repetida de regras simples, produzindo padrões auto‑semelhantes de complexidade arbitrária. Desde o trabalho de Benoît Mandelbrot, eles se tornaram um objeto clássico de estudo em sistemas dinâmicos, matemática computacional e arte generativa.

A **FractalDSL** é uma linguagem declarativa para descrever e gerar fractais. Em vez de exigir que o usuário implemente cada detalhe do laço de iteração, da aritmética de números complexos ou do algoritmo de escolha de transformações, a linguagem oferece um vocabulário pequeno e ortogonal de primitivas matemáticas — equação, constantes, iterações, centro, zoom, transformações afins, composição — que, combinadas, descrevem inequivocamente um fractal e sua visualização.

A decisão central de projeto desta entrega foi implementar a FractalDSL como uma **DSL embutida em Lisp** (concretamente, Guile/Scheme). Essa escolha substitui o protótipo externo com gramática ANTLR apresentado na Entrega 1 e traz três consequências: a sintaxe passa a ser a de S‑expressões, com toda a uniformidade e homoiconicidade do Lisp; as primitivas tornam‑se funções e macros de primeira classe, componíveis como qualquer outra função Scheme; e o esforço de desenvolvimento desloca‑se da construção de um *front‑end* léxico/sintático para a especificação semântica de cada primitiva — que é o que realmente caracteriza a linguagem.

A relevância do projeto está nesse contraste entre uma linguagem pequena e um domínio visualmente rico: com poucas primitivas é possível expressar desde fractais clássicos de escape (Mandelbrot, Julia) até sistemas de funções iteradas (Sierpinski, Barnsley), e ainda compor fractais entre si através da primitiva `with-depth`. A FractalDSL serve, assim, tanto como ferramenta de experimentação em dinâmica não‑linear quanto como estudo de caso sobre as vantagens de embutir uma DSL em uma linguagem hospedeira de sintaxe minimalista.

## Slides

Apresentação da Entrega Parcial 2:
https://docs.google.com/presentation/d/10naGQ4RjR8_f-cv5AV4XOGkLfsZSKpaQo51NQn4ITik/edit?usp=sharing

## Sintaxe da Linguagem na Forma de Tutorial

A FractalDSL herda do Lisp a sintaxe de **S‑expressões**: todo programa é uma árvore de listas entre parênteses em que o primeiro elemento é o operador e os demais são seus argumentos.

```scheme
(operador arg1 arg2 ...)
```

Não há precedência implícita, não há operadores infixos e não há diferença sintática entre *declarar* um fractal e *operar* sobre ele — em ambos os casos estamos apenas escrevendo uma chamada de função ou macro. Dessa uniformidade decorrem três propriedades que organizam todo o tutorial:

1. **Toda primitiva é uma função ou macro.** `create-fractal`, `equation`, `iterations`, `ifs`, `with-depth`, `generate` — todas são invocadas da mesma maneira. Não existem comandos, declarações ou blocos especiais; existem apenas aplicações.
2. **Fractais são valores de primeira classe.** Um fractal é apenas o valor devolvido por `create-fractal` (possivelmente transformado por outras primitivas). Ele pode ser atribuído a uma variável, passado como argumento, armazenado em uma estrutura ou usado *dentro* de outro fractal — é o que a primitiva `with-depth` explora.
3. **Configurar um fractal é compor funções.** Cada primitiva de parâmetro recebe um fractal como *primeiro* argumento e devolve um novo fractal com o campo correspondente atualizado. A configuração é, portanto, um pipeline funcional sem mutação.

### Criando um fractal

```scheme
(define mandelbrot (create-fractal "Mandelbrot"))
```

O valor retornado é uma *association list* com os campos básicos (`name`, `equation`, `constants`, `iterations`, `center`, `zoom`).

### Configurando por composição

Como cada primitiva devolve um fractal novo, a configuração é um pipeline lido "de dentro para fora":

```scheme
(define mandelbrot
  (zoom
    (center
      (iterations
        (equation (create-fractal "Mandelbrot") "z=z^2+c")
        500)
      -0.5 0)
    200))
```

Primeiro o fractal é criado, depois a equação é atribuída, depois o número de iterações, depois o centro e, por fim, o zoom. Cada passo produz um valor novo; o estado é imutável.

### Definindo a dinâmica

A regra iterativa é passada como *string* para `equation`, e os valores de parâmetros são fixados por `constant`:

```scheme
(define julia
  (constant
    (equation (create-fractal "Julia") "z=z^2+c")
    'c (cons -0.4 0.6)))        ;; c = -0.4 + 0.6i
```

A biblioteca implementa internamente as operações complexas (`c+`, `c-`, `c*`, `c/`, `c-pow`) necessárias para avaliar a equação ao longo das iterações.

### Sistemas de Funções Iteradas

Para fractais descritos por um conjunto de transformações afins, `ifs` anexa ao fractal uma lista de pares (probabilidade, afim). Tecnicamente é uma macro, mas sua aparência é a de uma forma especial:

```scheme
(define sierpinski
  (ifs (create-fractal "Sierpinski")
    (transform 0.33 (affine 0.5 0.0 0.0 0.5 0.0  0.0))
    (transform 0.33 (affine 0.5 0.0 0.0 0.5 0.5  0.0))
    (transform 0.34 (affine 0.5 0.0 0.0 0.5 0.25 0.5))))
```

Cada `(affine a b c d e f)` representa a transformação $T(x,y) = (ax+by+e,\ cx+dy+f)$.

### Composição: fractais como blocos de construção

A primitiva `with-depth` é o que torna a FractalDSL genuinamente composicional. Ela permite que um `transform` receba, no lugar de uma `affine`, **outro fractal já definido**, a ser expandido recursivamente até a profundidade indicada:

```scheme
(define combinado
  (ifs (create-fractal "Combinado")
    (transform 0.5 (with-depth 5 sierpinski))
    (transform 0.5 (with-depth 3 barnsley))))
```

Esse é o traço que fecha o ciclo "fractais são valores": um fractal passa a ser usável como sub‑expressão de outro, sem que seja necessário estender a sintaxe da linguagem.

### Executando

```scheme
(generate mandelbrot)
```

`generate` é o único ponto de entrada. Ele inspeciona o fractal recebido: se existe campo `ifs`, delega ao iterador de funções iteradas; se existe `equation` como *string*, parseia a expressão e itera no plano complexo. Trata‑se de **despacho polimórfico** sobre a forma do valor — o usuário não precisa saber qual mecanismo está em uso.

## Gramática da Linguagem

Por ser embutida, a sintaxe concreta da FractalDSL é a própria sintaxe das S‑expressões do Scheme. A gramática abaixo, em EBNF, descreve apenas as formas **semanticamente válidas** aceitas pela linguagem:

```
programa    ::= { forma } ;
forma       ::= definicao | "(" "generate" ident ")" ;
definicao   ::= "(" "define" ident fractal ")" ;

fractal     ::= "(" "create-fractal" string ")"
              | "(" param fractal arg+ ")"
              | "(" "ifs"  fractal transform+ ")" ;

param       ::= "equation" | "constant" | "iterations"
              | "center"   | "zoom"     | "resolution" | "color" ;

transform   ::= "(" "transform" numero corpo ")" ;
corpo       ::= "(" "affine" numero numero numero numero numero numero ")"
              | "(" "with-depth" numero ident ")" ;

arg         ::= numero | string | "'" ident | complexo ;
complexo    ::= "(" ("cons" | "make-c") numero numero ")" ;
```

A propriedade essencial é que todo construtor de fractal — `create-fractal`, um parâmetro qualquer ou `ifs` — devolve um valor do não‑terminal `fractal`. É essa propriedade de "fechamento" que garante a composicionalidade das primitivas. Tokens (`ident`, `numero`, `string`) seguem a convenção léxica do Scheme.

## Notebook

A implementação executável está no notebook em conjunto com o README.md.

## Exemplos Selecionados

Foram escolhidos quatro exemplos, cada um destacando um aspecto distinto da linguagem e um conceito clássico de projeto de linguagens.

### 1. Mandelbrot — equação como configuração

```scheme
(define mandelbrot
  (zoom
    (center
      (iterations
        (equation (create-fractal "Mandelbrot") "z=z^2+c")
        500)
      -0.5 0)
    200))

(generate mandelbrot)
```

Ilustra o **pipeline funcional** de configuração: cada primitiva é uma função pura que recebe um fractal e devolve outro. Sem mutação, sem ordem imperativa. `generate` reconhece a presença de `equation` e dispara o laço de escape no plano complexo.

### 2. Julia — parametrização com `constant`

```scheme
(define julia
  (zoom
    (center
      (constant
        (iterations
          (equation (create-fractal "Julia") "z=z^2+c")
          500)
        'c (cons -0.4 0.6))
      0 0)
    150))
```

A equação é a mesma do Mandelbrot, mas agora a constante `c` é fixada. Isso transforma uma única equação em uma **família paramétrica** de fractais, mostrando como a separação entre "regra" e "parâmetros" é capturada diretamente pelas primitivas.

### 3. Sierpinski — IFS e macros

```scheme
(define sierpinski
  (ifs (create-fractal "Sierpinski")
    (transform 0.33 (affine 0.5 0.0 0.0 0.5 0.0  0.0))
    (transform 0.33 (affine 0.5 0.0 0.0 0.5 0.5  0.0))
    (transform 0.34 (affine 0.5 0.0 0.0 0.5 0.25 0.5))))

(generate sierpinski)
```

Exemplo canônico de IFS: três transformações afins de razão 1/2, cada uma com probabilidade aproximada de 1/3. Mostra o uso de `ifs` como **macro** (uma forma sintática variádica traduzida em tempo de leitura para uma lista de transformações) e a transição de um mecanismo de iteração para outro sem que o resto da linguagem mude — é o mesmo `generate`, mas agora tomando o caminho do IFS.

### 4. Combinado — `with-depth` e fractais como valores

```scheme
(define combinado
  (ifs (create-fractal "Combinado")
    (transform 0.5 (with-depth 5 sierpinski))
    (transform 0.5 (with-depth 3 barnsley))))

(generate combinado)
```

É o exemplo que melhor revela o caráter da FractalDSL: um fractal cujos ramos são **outros fractais já definidos**, cada um expandido até uma profundidade própria. Ilustra ao mesmo tempo três ideias recorrentes em projeto de linguagens — cidadania de primeira classe (um fractal é um valor como outro qualquer), composicionalidade (novas construções emergem da combinação das antigas) e generalização sem extensão sintática (a linguagem ganha poder expressivo sem crescer em superfície).

## Discussão

Três observações de ordem linguística sobressaem à implementação.

A primeira é que **a sintaxe de S‑expressões fez quase todo o trabalho**. Nenhuma das primitivas exigiu uma forma sintática própria: `equation`, `iterations`, `center`, `zoom`, `color` e `resolution` são funções comuns, e as únicas macros do sistema (`ifs`, `with-depth`) existem apenas porque são variádicas ou recebem expressões não avaliadas. Isso reforça a tese de que, quando a linguagem hospedeira tem sintaxe mínima e homoicônica, a fronteira entre "DSL" e "biblioteca" quase desaparece.

A segunda é que **despacho polimórfico em `generate` resolveu um problema que a gramática externa da Entrega 1 teria tornado visível**. Na proposta anterior, haveria uma distinção sintática explícita entre fractais de escape e fractais IFS. Na versão embutida, essa distinção é eliminada: `generate` inspeciona o valor e escolhe o mecanismo, de modo que o usuário descreve *o que* é o fractal, não *como* iterá‑lo.

A terceira é que **`with-depth` foi a primitiva que mais explicitou o ganho do embedding**. Sem ela, a linguagem ainda seria útil, mas limitada a fractais atômicos. Com ela, fractais passam a ser blocos de construção — e essa generalização foi obtida sem alterar a gramática, apenas tornando um valor aceitável onde antes só era aceita uma transformação afim. É um ganho típico do paradigma: *first‑class everything* produz composicionalidade quase de graça.

Entre as limitações, a mais relevante é o **escopo restrito do parser de `equation`**, que hoje reconhece essencialmente `z^n ± c` e `z*z+c`. Expressões mais livres ainda exigiriam uma extensão do parser — ou, como será discutido adiante, a substituição da *string* por uma S‑expressão.

## Conclusão

A principal conclusão deste ciclo é que **migrar a FractalDSL para uma DSL embutida em Lisp foi a decisão mais consequente do projeto**. Ela permitiu que o foco se deslocasse da construção de um *front‑end* para a especificação semântica das primitivas, e tornou possível introduzir `with-depth` — uma primitiva genuinamente composicional — sem precisar estender a gramática.

Os desafios não foram tanto de implementação quanto de *disciplina de projeto*: decidir quais primitivas são realmente necessárias, qual o contrato de cada uma, e como `generate` deveria reconciliar os dois mecanismos de iteração. A regra adotada — primitivas pequenas e ortogonais, `generate` como único ponto de entrada, macros usadas apenas onde a avaliação das S‑expressões não basta — revelou‑se estável: nenhum dos exemplos construídos exigiu uma primitiva nova.

As lições aprendidas podem ser resumidas em três. Primeira, a **uniformidade sintática** das S‑expressões não é apenas estética: ela elimina classes inteiras de decisões de design (precedência, delimitadores, pontuação), permitindo concentrar atenção na semântica. Segunda, **valores de primeira classe e composicionalidade são inseparáveis**: foi justamente porque fractais já eram valores comuns que `with-depth` pôde ser acrescentada de forma natural. Terceira, **separar definição e execução** em dois conjuntos disjuntos de primitivas — tudo o que constrói/configura um fractal de um lado, `generate` do outro — rendeu uma linguagem mais fácil de entender e de estender.

# Trabalhos Futuros

A extensão mais imediata seria **substituir a *string* da equação por uma S‑expressão**. Em vez de `(equation f "z=z^2+c")`, escrever `(equation f '(+ (pow z 2) c))` permitiria reusar o leitor do próprio Scheme como parser, aceitar expressões arbitrárias sem adicionar casos e abrir espaço para funções transcendentes (`sin`, `cos`, `exp`). Seria também a oportunidade de tornar `c+`, `c*` e `c-pow` diretamente acessíveis ao usuário, sem o passo intermediário do parser.

Em paralelo, valeria construir um **back‑end de renderização real**, que traduza a lista de pontos (no caso de IFS) ou o mapa de iterações (no caso de equações) em uma imagem em disco, honrando os parâmetros de `resolution` e `color`. Isso fecharia o ciclo "descrever → gerar → visualizar" atualmente interrompido na última etapa.

Entre os desdobramentos possíveis, a FractalDSL pode evoluir em três direções. Na direção **pedagógica**, acoplar‑se a um notebook interativo para explorar dinâmica não‑linear variando parâmetros em tempo real. Na direção **expressiva**, ganhar novas primitivas de composição (`overlay`, `warp`, `color-map`) mantendo o mesmo compromisso de ortogonalidade. Na direção **formal**, documentar a semântica operacional das primitivas e investigar análises estáticas — por exemplo, detecção de fractais mal‑formados antes da execução.

# Referências Bibliográficas

BARNSLEY, Michael F. *Fractals Everywhere*. 2. ed. San Diego: Academic Press, 1993.

GLEICK, James. *Chaos: making a new science*. New York: Viking, 1987.

HUDAK, Paul. Building domain‑specific embedded languages. *ACM Computing Surveys*, v. 28, n. 4es, p. 196‑es, dez. 1996.

MANDELBROT, Benoît B. *The Fractal Geometry of Nature*. New York: W. H. Freeman, 1982.

SUSSMAN, Gerald J.; ABELSON, Harold; SUSSMAN, Julie. *Structure and Interpretation of Computer Programs*. 2. ed. Cambridge: MIT Press, 1996.

SPRINGER, George; FRIEDMAN, Daniel P. *Scheme and the Art of Programming*. Cambridge: MIT Press, 1989.
