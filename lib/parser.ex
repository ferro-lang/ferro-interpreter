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
          | {:identifier_literal, String.t()}
          | {:binary_operation, operation(), expression(), expression()}
          | {:assignment_operation, String.t(), expression()}

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

      [:let, {:identifier, name}, :assignment | tail_] ->
        {expression, tail__} = parse_statement(tail_)
        parse(tail__, [{:assignment_operation, name, expression} | acc])

      _ ->
        {expression, tail} = parse_statement(tokens)
        parse(tail, [expression | acc])
    end
  end

  defp parse_statement(tokens) do
    {lhs, tail} = parse_multiplicative_expression(tokens)

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

  defp parse_multiplicative_expression(tokens) do
    {lhs, tail} = parse_division_expression(tokens)

    case tail do
      [{:operation, :multiply} | tail_] ->
        {rhs, tail__} = parse_statement(tail_)
        {{:binary_operation, {:operation, :multiply}, lhs, rhs}, tail__}

      _ ->
        {lhs, tail}
    end
  end

  defp parse_division_expression(tokens) do
    {lhs, tail} = parse_primary_expression(tokens)

    case tail do
      [{:operation, :divide} | tail_] ->
        {rhs, tail__} = parse_division_expression(tail_)
        {{:binary_operation, {:operation, :divide}, lhs, rhs}, tail__}

      [{:operation, :modulus} | tail_] ->
        {rhs, tail__} = parse_statement(tail_)
        {{:binary_operation, {:operation, :modulus}, lhs, rhs}, tail__}

      _ ->
        {lhs, tail}
    end
  end

  defp parse_primary_expression(tokens) do
    case tokens do
      [{:integer, i} | tail] ->
        {{:integer_literal, i}, tail}

      [{:float, f} | tail] ->
        {{:float_literal, f}, tail}

      [{:identifier, n} | tail] ->
        {{:identifier_literal, n}, tail}

      [:lparen | tail] ->
        {expression, tail_} = parse_statement(tail)

        case tail_ do
          [:rparen | tail__] -> {expression, tail__}
          [token | _] -> raise "Parser error: Expected closing parenthesis, got #{token}"
        end

      [token | _] ->
        raise "Parser error: Encountered invalid token, got #{token}!"
    end
  end
end
