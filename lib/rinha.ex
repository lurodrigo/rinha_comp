defmodule Rinha do
  alias Rinha.Stdlib

  def file_to_ir(file) do
    file
    |> File.read!()
    |> Jason.decode!()
    |> Map.get("expression")
    |> to_ir()
  end

  defp from_text(%{"text" => text}), do: String.to_atom(text)

  def to_ir(%{"kind" => "Let"} = node) do
    {:let, from_text(node["name"]), to_ir(node["value"]), to_ir(node["next"])}
  end

  def to_ir(%{"kind" => "Var"} = node) do
    {:var, String.to_atom(node["text"])}
  end

  def to_ir(%{"kind" => "Call"} = node) do
    {:call, to_ir(node["callee"]), Enum.map(node["arguments"], &to_ir/1)}
  end

  def to_ir(%{"kind" => "Function"} = node) do
    {:fn, Enum.map(node["parameters"], &{:var, from_text(&1)}), to_ir(node["value"])}
  end

  def to_ir(%{"kind" => "If"} = node) do
    {:if, to_ir(node["condition"]), to_ir(node["then"]), to_ir(node["otherwise"])}
  end

  def to_ir(%{"kind" => "Binary"} = node) do
    op =
      case node["op"] do
        "Add" -> {Stdlib, :add}
        "Sub" -> {Kernel, :-}
        "Mul" -> {Kernel, :*}
        "Div" -> {Kernel, :div}
        "Rem" -> {Kernel, :rem}
        "Eq" -> {Kernel, :==}
        "Neq" -> {Kernel, :!=}
        "Lt" -> {Kernel, :<}
        "Lte" -> {Kernel, :<=}
        "Gt" -> {Kernel, :>}
        "Gte" -> {Kernel, :>=}
        "And" -> {Kernel, :&&}
        "Or" -> {Kernel, :||}
      end

    {:call, op, [to_ir(node["lhs"]), to_ir(node["rhs"])]}
  end

  def to_ir(%{"kind" => kind, "value" => value}) when kind in ["Int", "Str", "Bool"], do: value

  def to_ir(%{"kind" => "Print"} = node) do
    {:call, {Stdlib, :print}, [to_ir(node["value"])]}
  end

  def to_ir(%{"kind" => "Tuple"} = node) do
    {:call, {Stdlib, :tuple}, [to_ir(node["value"])]}
  end

  def to_ir(%{"kind" => "First"} = node) do
    {:call, {Stdlib, :first}, [to_ir(node["value"])]}
  end

  def to_ir(%{"kind" => "Second"} = node) do
    {:call, {Stdlib, :second}, [to_ir(node["value"])]}
  end

  def var(name), do: {name, [], Elixir}

  def ir_to_elixir({:let, name, {:fn, _, _} = func, next}) do
    quote do
      unquote(var(name)) =
        Stdlib.fix(fn unquote(var(name)) ->
          unquote(ir_to_elixir(func))
        end)

      unquote(ir_to_elixir(next))
    end
  end

  def ir_to_elixir({:let, :_, value, next}) do
    quote do
      unquote(ir_to_elixir(value))
      unquote(ir_to_elixir(next))
    end
  end

  def ir_to_elixir({:let, name, value, next}) do
    quote do
      unquote(var(name)) = unquote(ir_to_elixir(value))
      unquote(ir_to_elixir(next))
    end
  end

  def ir_to_elixir({:var, name}) do
    quote do
      unquote(var(name))
    end
  end

  def ir_to_elixir({:fn, params, body}) do
    quote do
      fn [unquote_splicing(Enum.map(params, &ir_to_elixir/1))] -> unquote(ir_to_elixir(body)) end
    end
  end

  def ir_to_elixir({:if, condition, then, otherwise}) do
    quote do
      if unquote(ir_to_elixir(condition))
         |> tap(&(is_boolean(&1) || raise("condition must be a boolean"))) do
        unquote(ir_to_elixir(then))
      else
        unquote(ir_to_elixir(otherwise))
      end
    end
  end

  def ir_to_elixir({:call, {:var, var_name}, args}) do
    quote do
      unquote(var(var_name)).([unquote_splicing(Enum.map(args, &ir_to_elixir/1))])
    end
  end

  def ir_to_elixir({:call, {module, op}, args}) do
    quote do
      unquote(module).unquote(op)(unquote_splicing(Enum.map(args, &ir_to_elixir/1)))
    end
  end

  def ir_to_elixir({:call, lambda, args}) do
    quote do
      unquote(ir_to_elixir(lambda)).(unquote_splicing(Enum.map(args, &ir_to_elixir/1)))
    end
  end

  def ir_to_elixir(primitive), do: primitive

  def transpile(file) when is_binary(file), do: file_to_ir(file) |> transpile()

  def transpile(ast) do
    quote do
      alias Rinha.Stdlib
      unquote(ir_to_elixir(ast))
    end
  end

  def print_transpiled(file_or_ast), do: transpile(file_or_ast) |> Macro.to_string() |> IO.puts()

  def run(file_or_ast), do: transpile(file_or_ast) |> Code.eval_quoted()
end
