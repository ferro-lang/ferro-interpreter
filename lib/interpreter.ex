defmodule Interpreter do
  alias Parser

  # Defining the runtime types.
  @type runtime_value ::
          {:integer_value, integer()}
          | {:float_value, float()}
          | {:nil_value, nil}
          | {:bool_value, boolean()}

  # Main Interpreter logic.
  def eval(program), do: eval(program, make_global_scope())
  def eval({:program, []}, _), do: {:nil_value, nil}
  def eval(program, scope), do: eval(program, [], scope)

  def make_global_scope(),
    do: %{true: {:bool_value, true}, false: {:bool_value, false}, nil: {:nil_value, nil}}

  defp eval(program, acc, scope) do
    case program do
      {:program, expressions} -> eval_expr_batch(expressions, acc, scope)
      _ -> "Interpreter internal error: Expected program!"
    end
  end

  defp eval_expr_batch([], [runtime_value | _], _), do: runtime_value

  defp eval_expr_batch([expression | tail], acc, scope) do
    {runtime_value, new_scope} = eval_expr(expression, scope)
    eval_expr_batch(tail, [runtime_value | acc], new_scope)
  end

  defp eval_expr(expression, scope) do
    case expression do
      {:integer_literal, i} ->
        {{:integer_value, i}, scope}

      {:float_literal, i} ->
        {{:float_value, i}, scope}

      {:identifier_literal, name} ->
        if Map.has_key?(scope, name) do
          {Map.get(scope, name), scope}
        else
          raise "RuntimeError: Variable #{name} does not exists!"
        end

      {:binary_operation, {:operation, op}, lhs, rhs} ->
        eval_binary_operation(op, lhs, rhs, scope)

      {:assignment_operation, name, aexpr} ->
        {val, _} = eval_expr(aexpr, scope)
        new_scope = Map.put(scope, name, val)
        {{:nil_value, nil}, new_scope}

      _ ->
        dbg(expression)

        raise "Interpreter internal error: Interpreter, is not capable of exectuing the following expressiong!"
    end
  end

  defp eval_binary_operation(op, lhs, rhs, scope) do
    {lval, _} = eval_expr(lhs, scope)
    {rval, _} = eval_expr(rhs, scope)

    {apply_operation(op, lval, rval), scope}
  end

  defp apply_operation(op, {:integer_value, li}, {:integer_value, ri}),
    do: eval_operation(op, li, ri, :integer_value)

  defp apply_operation(op, {:float_value, li}, {:integer_value, ri}),
    do: eval_operation(op, li, ri, :float_value)

  defp apply_operation(op, {:integer_value, li}, {:float_value, ri}),
    do: eval_operation(op, li, ri, :float_value)

  defp apply_operation(op, {:float_value, li}, {:float_value, ri}),
    do: eval_operation(op, li, ri, :float_value)

  defp apply_operation(_, _, _) do
    raise("Interpreter error: Unsupported operation!")
  end

  defp eval_operation(:addition, li, ri, atom), do: {atom, li + ri}
  defp eval_operation(:reduction, li, ri, atom), do: {atom, li - ri}
  defp eval_operation(:multiply, li, ri, atom), do: {atom, li * ri}
  defp eval_operation(:divide, li, ri, _), do: {:float_value, li / ri}

  defp eval_operation(:modulus, _, _, _),
    do: raise("Interpreter internal error: Modulus operations are currently beyond capability.")
end
