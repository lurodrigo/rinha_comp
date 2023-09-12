# Rinha

Essa é um transpiler implementado em Elixir para a [Rinha de Compiladores](https://github.com/aripiprazole/rinha-de-compiler). Ele usa o próprio mecanismo de `quote`/`unquote` da linguagem
pra transformar a AST dada em código elixir e então o executa usando `Code.eval_quoted`.

## Objetivos

- Gastar pouco tempo (umas três horas, até este momento, mais ou menos)
- Concisão (~ 150 linhas)
- Completude (acredito que cumpre toda a especificação, exceto talvez pelos inteiros serem unbounded)
- Simplicidade, clareza e elegância. Um entendimento básico de `quote`/`unquote` e recursão deve ser suficiente
  para entender o funcionamento.

## Não-objetivos

- Eficiência

## Implementação

O transpiler tem três partes.

- Uma "stdlib": a semântica da linguagem dada não é exatamente a mesma que elixir. Em particular
  - O operador `+` é overloaded (em Elixir usamos `+` para números e `<>` para string)
  - Similarmente, `print` aqui aceita múltiplos tipos, em comparação com `IO.puts` que é mais estrito.
  - Um operador de ponto fixo (y combinator) (mais sobre isso abaixo)
- Uma etapa de IR (talvez eu esteja abusando um pouco do termo aqui) que transforma o JSON em uma
  representação intermediária mais conveniente em elixir (em termos de listas, tuplas, átomos e literais primitivos)
- Uma etapa de transpilação da IR para elixir usando `quote`/`unquote`.
  - A transpilação é feita praticamente de forma 1-para-1 entre um nó da AST original e um nó da AST elixir. Não carregamos nenhum contexto na recursão. A implementação é feita em duas etapas apenas por clareza, mas poderia ter sido feita em apenas um passo sem carregar contexto.
  - A única transformação que não pode ser feita de forma direta entre a linguagem da rinha e elixir é a implementação de funções recursivas. Em elixir não é possível definir funções anônimas recursivas, portanto usei o combinador Y e listas de parâmetros para implementá-las.

Só agora que ia publicar notei que o [colega aqui](https://github.com/rwillians/rinha-de-compilers--elixir-transcompiler/tree/main) já tinha feito uma implementação em elixir
com ideias similares. Então listo aqui umas diferenças de abordagem:

- Aqui tudo roda em tempo de execução (pode parece curioso, mas `quote`/`unquote` podem ser usados em runtime, sem macros ou metaprogramação a nível de módulo), tanto a transpilação quando a execução.
- Uso apenas tuplas, listas e primitivos para representar a AST, sem definir structs ou typespecs.
- É possível resolver o problema de definição de funções recursivas usando módulos, mas isso cria certas demandas sobre a ordem de definição deles,
  o que é particularmente complicado para a execução de side-effects `let _ = print ...` ou redefinição de uma
  função com o mesmo nome. Optei por usar funções anônimas + combinador Y por reduzir a implementação, já que a semântica de shadowing em elixir bate com a da linguagem da rinha.

## Rodando diretamente

Clone este repo e navegue até ele. Presumindo que você já tem o `asdf` instalado, clone este repo, vá até ele
e faça:

```bash
asdf install
mix deps.get
```

Instalados os pré requisitos, o transpiler pode ser executado em três modos.

### Modo `ir`

Mostro a representação interna:

```elixir
#> mix run rinha.exs ir files/fib.json
{:let, :fib,
 {:fn, [var: :n],
  {:if, {:call, {Kernel, :<}, [{:var, :n}, 2]}, {:var, :n},
   {:call, {Rinha.Stdlib, :add},
    [
      {:call, {:var, :fib}, [{:call, {Kernel, :-}, [{:var, :n}, 1]}]},
      {:call, {:var, :fib}, [{:call, {Kernel, :-}, [{:var, :n}, 2]}]}
    ]}}}, {:call, {Rinha.Stdlib, :print}, [{:call, {:var, :fib}, '\n'}]}}
```

### Modo `transpile`

Mostra o código elixir gerado

```elixir
#> mix run rinha.exs transpile files/fib.json
alias Rinha.Stdlib

(
  fib =
    Stdlib.fix(fn fib ->
      fn [n] ->
        if Kernel.<(n, 2) do
          n
        else
          Rinha.Stdlib.add(fib.([Kernel.-(n, 1)]), fib.([Kernel.-(n, 2)]))
        end
      end
    end)

  Rinha.Stdlib.print(fib.('\n'))
)

```

### Modo `run`

Executa, de fato

```bash
$ mix run rinha.exs run files/fib.json
55
```

## Rodando via Docker

# TODO
