defmodule Interpreter do
  alias Parser

  # Defining the runtimetypes.
  @type runtime_value ::
          {:integer_value, integer()}
          | {:float_value, float()}
          | {:nil_value, nil}
          | {:bool_value, boolean()}
          | {:function, list(String.t()), list(), %{}}
          | {:return_value, runtime_value()}

  # Main Interpreter logic.
  def eval(program), do: eval(program, Scope.make_global_scope())
  def eval({:program, []}, _), do: {:nil_value, nil}
  def eval(program, scope), do: eval(program, [], scope)

  defp make_local_scope(scope) do
    Scope.deepclone(scope)
  end

  defp(eval(program, acc, scope)) do
    case program do
      {:program, expressions} -> eval_expr_batch(expressions, acc, scope)
      _ -> "Interpreter internal error: Expected program!"
    end
  end

  defp eval_expr_batch([], [runtime_value | _], _), do: runtime_value

  defp eval_expr_batch([expression | tail], acc, scope) do
    {runtime_value, new_scope} = eval_expr(expression, scope)

    case runtime_value do
      {:return_value, _} -> {runtime_value, new_scope}  # Propagate return immediately
      _ -> eval_expr_batch(tail, [runtime_value | acc], new_scope)
    end
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
          raise "RuntimeError: Variable #{name} does not exist!"
        end

      {:binary_operation, {:operation, op}, lhs, rhs} ->
        eval_binary_operation(op, lhs, rhs, scope)

      {:assignment_operation, name, aexpr} ->
        {val, _} = eval_expr(aexpr, scope)
        new_scope = Map.put(scope, name, val)
        {{:nil_value, nil}, new_scope}

      {:function_declaration, name, arguments, {:block, block}} ->
        new_scope = Map.put(scope, name, {:function, arguments, block, scope})
        {Map.get(new_scope, name), new_scope}

      {:return_operation, expression} ->
        {val, new_scope} = eval_expr(expression, scope)
        {{:return_value, val}, new_scope}  # Mark return value

      {:function_call_operation, name, parameters} ->
        if Map.has_key?(scope, name) do
          {:function, arguments, block, fn_scope} = Map.get(scope, name)

          evaluated_params =
            Enum.map(parameters, fn param ->
              {val, _} = eval_expr(param, scope)
              val
            end)

          variables = Enum.zip(arguments, evaluated_params)
          fn_scope = Enum.into(variables, make_local_scope(fn_scope))
          {val, new_scope} = eval_block(block, scope, fn_scope, [])

          case val do
            {:return_value, inner_val} -> {inner_val, new_scope}  # Return actual value
            _ -> {{:nil_value, nil}, new_scope}  # Return nil if no explicit return
          end
        else
          raise "RuntimeError: Function #{name} isn't defined!"
        end

      _ ->
        raise "Interpreter internal error: Cannot execute expression!"
    end
  end

  defp eval_block([], parent_scope, _, [val | _]), do: {val, parent_scope}

  defp eval_block([expression | tail], parent_scope, block_scope, runtime_values) do
    {val, new_scope} = eval_expr(expression, block_scope)
    normalized_scope = Scope.normalize(parent_scope, new_scope)

    case val do
      {:return_value, _} -> {val, normalized_scope}  # Propagate return value immediately
      _ -> eval_block(tail, normalized_scope, new_scope, [val | runtime_values])
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
end
