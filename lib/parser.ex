defmodule Parser do
  alias Lexer

  # Defining the types for operators
  @type operation ::
          :addition
          | :reduction

  # Defining the expression types.
  @type expression ::
          {:integer_literal, integer()}
          | {:float_literal, float()}
          | {:binary_operation, operation(), expression(), expression()}

  @type program ::
          {:program, list(expression())}

  # Main parser logic.
  def parse(tokens) do
    parse(tokens, [])
  end

  defp parse(tokens, acc) do
    case tokens do
      [] ->
        raise "Parser error: Unexpected EOF!"

      [:eof] ->
        {:program, Enum.reverse(acc)}

      _ ->
        {expression, tail} = parse_statement(tokens)
        parse(tail, [expression | acc])
    end
  end

  defp parse_statement(tokens) do
    {lhs, tail} = parse_additive_expression(tokens)

    case tail do
      [{:operation, :plus} | tail_] ->
        {rhs, tail__} = parse_statement(tail_)
        {{:binary_operation, {:operation, :addition}, lhs, rhs}, tail__}

      [{:operation, :minus} | tail_] ->
        {rhs, tail__} = parse_statement(tail_)
        {{:binary_operation, {:operation, :reduction}, lhs, rhs}, tail__}

      _ ->
        {lhs, tail}
    end
  end

  defp parse_additive_expression(tokens) do
    parse_primary_expression(tokens)
  end

  defp parse_primary_expression(tokens) do
    case tokens do
      [{:integer, i} | tail] -> {{:integer_literal, i}, tail}
      [{:float, f} | tail] -> {{:float_literal, f}, tail}
      _ -> raise "Lexer error: Encountered invalid token!"
    end
  end
end
