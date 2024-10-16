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
          | {:string_literal, String.t()}
          | {:binary_operation, operation(), expression(), expression()}
          | {:assignment_operation, String.t(), expression()}
          | {:block, list(expression())}
          | {:function_declaration, String.t(), list(String.t()), expression()}
          | {:function_call_operation, String.t(), list(expression())}
          | {:return_operation, expression()}
          | {:external_function_declaration, String.t(), String.t(), expression()}

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
    case tokens do
      [:open, {:identifier, name} | tail] ->
        {{:open_operation, name}, tail}

      [
        :external,
        :lparen,
        {:string, elixir_file},
        :comma,
        {:string, elixir_function},
        :rparen | tail
      ] ->
        {external_function, tail_} = parse_statement(tail)
        {{:external_function_declaration, elixir_file, elixir_function, external_function}, tail_}

      [{:identifier, name}, :lparen | tail] ->
        {parameters, tail_} = parse_parameters(tail, [])
        {{:function_call_operation, name, parameters}, tail_}

      [:let, {:identifier, name}, :assignment | tail_] ->
        {statement, tail__} = parse_statement(tail_)
        {{:assignment_operation, name, statement}, tail__}

      [:fn, {:identifier, name}, :lparen | tail_] ->
        {arguments, tail__} = parse_arguments(tail_, [])
        {block, tail___} = parse_block(tail__)
        {{:function_declaration, name, arguments, block}, tail___}

      [:return | tail] ->
        {statement, tail_} = parse_statement(tail)
        {{:return_operation, statement}, tail_}

      _ ->
        {expression, tail} = parse_expression(tokens)
        {expression, tail}
    end
  end

  # Parsing parameters.
  defp parse_parameters([:rparen | tail], acc), do: {Enum.reverse(acc), tail}

  defp parse_parameters(tokens, acc) do
    {expression, tail_} = parse_expression(tokens)

    case tail_ do
      [:comma | tail__] ->
        parse_parameters(tail__, [expression | acc])

      [:rparen | tail__] ->
        {Enum.reverse([expression | acc]), tail__}

      _ ->
        dbg(tail_)
        raise "Parser: Error: Encountered Invalid Token, expected a comma!"
    end
  end

  # Helper functions to parse, arguments for a function.
  defp parse_arguments([:rparen | tail], acc), do: {Enum.reverse(acc), tail}

  defp parse_arguments([{:identifier, name}, :comma | tail], acc),
    do: parse_arguments(tail, [name | acc])

  defp parse_arguments([{:identifier, name} | tail], acc),
    do: parse_arguments(tail, [name | acc])

  defp parse_arguments(_, _),
    do: raise("Parser error: Unexpected token found in function arguments!")

  defp parse_block([:lbrace | tail]), do: parse_block(tail, [])

  defp parse_block([:rbrace | tail], acc), do: {{:block, Enum.reverse(acc)}, tail}

  defp parse_block(tokens, acc) do
    {statement, tail} = parse_statement(tokens)
    parse_block(tail, [statement | acc])
  end

  defp parse_expression(tokens) do
    {lhs, tail} = parse_multiplicative_expression(tokens)

    case tail do
      [{:operation, :plus} | tail_] ->
        {rhs, tail__} = parse_expression(tail_)
        {{:binary_operation, {:operation, :addition}, lhs, rhs}, tail__}

      [{:operation, :minus} | tail_] ->
        {rhs, tail__} = parse_expression(tail_)
        {{:binary_operation, {:operation, :reduction}, lhs, rhs}, tail__}

      _ ->
        {lhs, tail}
    end
  end

  defp parse_multiplicative_expression(tokens) do
    {lhs, tail} = parse_division_expression(tokens, [])

    case tail do
      [{:operation, :multiply} | tail_] ->
        {rhs, tail__} = parse_expression(tail_)
        {{:binary_operation, {:operation, :multiply}, lhs, rhs}, tail__}

      _ ->
        {lhs, tail}
    end
  end

  defp parse_division_expression(tokens, acc) do
    {expr, tail} = parse_primary_expression(tokens)

    case tail do
      [{:operation, :divide} | tail_] ->
        parse_division_expression(tail_, [expr | acc])

      _ ->
        {align_division_expressions_into_order([expr | acc]), tail}
    end
  end

  defp align_division_expressions_into_order([head]), do: head

  defp align_division_expressions_into_order([head, tail]) do
    {:binary_operation, {:operation, :divide}, tail, head}
  end

  defp align_division_expressions_into_order([head | tail]) do
    {:binary_operation, {:operation, :divide}, align_division_expressions_into_order(tail), head}
  end

  defp parse_primary_expression(tokens) do
    case tokens do
      [{:integer, i} | tail] ->
        {{:integer_literal, i}, tail}

      [{:float, f} | tail] ->
        {{:float_literal, f}, tail}

      [{:identifier, n} | tail] ->
        case tail do
          # Check if the next token is an opening parenthesis
          :lparen ->
            {parameters, tail_} = parse_parameters(tail, [])
            {{:function_call_operation, n, parameters}, tail_}

          _ ->
            {{:identifier_literal, n}, tail}
        end

      [{:string, t} | tail] ->
        {{:string_literal, t}, tail}

      [:lparen | tail] ->
        {expression, tail_} = parse_expression(tail)

        case tail_ do
          [:rparen | tail__] -> {expression, tail__}
          [token | _] -> raise "Parser error: Expected closing parenthesis, got #{token}"
        end

      [token | _] ->
        raise "Parser error: Encountered invalid token, got #{token}!"
    end
  end
end
