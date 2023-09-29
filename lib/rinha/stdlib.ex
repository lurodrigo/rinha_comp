defmodule Rinha.Stdlib do
  defguard is_primitive(x) when is_integer(x) or is_binary(x) or is_boolean(x)
  defguard is_addable(x) when is_integer(x) or is_binary(x)
  defguard is_printable(x) when is_primitive(x) or is_function(x) or is_tuple(x)

  def as_string(x) when is_primitive(x), do: to_string(x)

  def as_string({x, y}), do: "(#{as_string(x)}, #{as_string(y)})"

  def as_string(x) when is_function(x), do: "<#closure>"

  def add(x, y) when is_integer(x) and is_integer(y), do: x + y

  def add(x, y) when is_addable(x) and is_addable(y), do: as_string(x) <> as_string(y)

  def print(x) when is_printable(x), do: IO.puts(as_string(x))

  def eq(x, y) when is_primitive(x) and is_primitive(y), do: x == y

  def neq(x, y) when is_primitive(x) and is_primitive(y), do: x != y

  def lt(x, y) when is_integer(x) and is_integer(y), do: x < y

  def lte(x, y) when is_integer(x) and is_integer(y), do: x <= y

  def gt(x, y) when is_integer(x) and is_integer(y), do: x > y

  def gte(x, y) when is_integer(x) and is_integer(y), do: x >= y

  def check_boolean!(x) when is_boolean(x), do: x

  def strict_and(x, y) when is_boolean(x) and is_boolean(y), do: x and y

  def strict_or(x, y) when is_boolean(x) and is_boolean(y), do: x or y

  @spec first({any, any}) :: any
  def first({x, _}), do: x
  def second({_, y}), do: y

  def tuple(x, y), do: {x, y}

  def fix(f) do
    # apply the second expression to itself
    (fn z ->
       z.(z)
     end).(fn x ->
      # the a here represents the parameters to the recursing function
      f.(fn a -> x.(x).(a) end)
    end)
  end
end
