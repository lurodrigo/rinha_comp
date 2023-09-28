defmodule Rinha.Stdlib do
  def as_string(x) when is_integer(x) when is_boolean(x) when is_binary(x),
    do: to_string(x)

  def as_string({x, y}), do: "{#{as_string(x)}, #{as_string(y)}}"

  def as_string(x) when is_function(x), do: "<#closure>"

  defguard is_printable(x)
           when is_integer(x) or is_binary(x) or is_boolean(x) or is_function(x) or is_tuple(x)

  def add(x, y) when is_integer(x) and is_integer(y), do: x + y

  def add(x, y) when is_printable(x) and is_printable(y), do: as_string(x) <> as_string(y)

  def print(x) when is_printable(x), do: IO.puts(as_string(x))

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
