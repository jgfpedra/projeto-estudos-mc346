# DSL `FractalDSL`

## Descrição Resumida da DSL

Fractais são estruturas geométricas geradas por processos iterativos simples que produzem padrões complexos e auto-semelhantes.  
Esses fenômenos foram amplamente popularizados pelo trabalho de Benoît Mandelbrot no estudo do conjunto de Mandelbrot.  
A DSL proposta oferece uma forma declarativa e concisa de descrever regras iterativas e parâmetros necessários para gerar e visualizar fractais.

> Motivação

Embora existam diversas ferramentas para geração e exploração de fractais, como Ultra Fractal, XaoS e Fractint, essas aplicações oferecem interfaces específicas ou dependem de configurações detalhadas.  
Uma DSL permite representar as regras matemáticas e transformações que geram os fractais, fornecendo uma forma mais estruturada e legível de descrever esses sistemas.

> Relevância

Ao formalizar a descrição de sistemas iterativos para geração de fractais, a linguagem pode servir como ferramenta de experimentação e ensino em matemática computacional e dinâmica não linear.  
Isso possibilita explorar diferentes configurações de equações e transformações de forma clara, facilitando a compreensão de como regras simples podem produzir comportamentos complexos.

## Slides

> Coloque aqui o link para o PDF da apresentação.

## Sintaxe da Linguagem na Forma de Tutorial

Esta linguagem permite a definição, configuração e renderização de fractais através de uma sintaxe declarativa simples.

---

### Definição de um Fractal

A construção básica utiliza a palavra-chave `fractal`, seguida pelo nome e um bloco de parâmetros.

```rust
fractal Mandelbrot {
    center (-0.5, 0)
    zoom 200
    iterations 500
}

#### Parâmetros:

* **fractal**: Inicia a definição de um fractal.
* **center**: Define o ponto central da região do plano complexo que será visualizada.
* **zoom**: Controla o nível de ampliação da imagem.
* **iterations**: Define o número máximo de iterações utilizadas no cálculo.

Esses parâmetros determinam a região e o nível de detalhe da visualização do fractal.

### Definição de equações iterativas

A linguagem permite especificar explicitamente a equação iterativa responsável pela geração do fractal.

```rust
fractal Julia {
    equation z = z^2 + c
    constant c = -0.4
    iterations 500
}

#### Parâmetros da Equação:

* **equation**: Define a regra iterativa aplicada repetidamente.
* **constant**: Define parâmetros utilizados na equação.
* **iterations**: Especifica quantas vezes a equação será aplicada durante o cálculo.

### Configuração de Renderização

A linguagem também permite definir parâmetros relacionados à visualização da imagem gerada.

```rust
render {
    resolution 800 800
    color gradient
}

#### Parâmetros da renderização:

* **resolution**: Define o tamanho da imagem gerada.
* **color**: Especifica o esquema de cores utilizado na visualização.

### Geração do Fractal

Após definir o fractal e os parâmetros de renderização, a imagem pode ser gerada com o comando `generate`.

```rust
generate Mandelbrot

Esse comando executa o processo iterativo definido e produz a visualização.

## Gramática da Linguagem

> Apresente a gramática da linguagem.

## Exemplos Selecionados

> Coloque um conjunto de exemplos selecionados e os resultados alcançados.

# Referências Bibliográficas

> https://en.wikipedia.org/wiki/Fractal-generating_software
> GLEICK, James. Chaos: making a new science. New York: Viking, 1987.
