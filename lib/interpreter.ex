defmodule Interpreter do
  alias Parser

  # Defining runtime types.
  @type runtime_value ::
          {:integer_value, integer()}
          | {:float_value, float()}
          | {:nil_value, nil}
          | {:bool_value, boolean()}
          | {:function, list(String.t()), list(), %{}}
          | {:return_value, runtime_value()}

  # Main Interpreter logic.
  def eval(program), do: eval(program, Scope.make_global_scope())

  def eval({:program, []}, _),
    do: raise("RuntimeError: 'main' function not declared in the program!")

  def eval(program, scope), do: eval(program, [], scope)

  defp make_local_scope(scope) do
    Scope.deepclone(scope)
  end

  defp(eval(program, acc, scope)) do
    case program do
      {:program, expressions} ->
        {_, returned_scope} = eval_expr_batch(expressions, acc, scope, :global)

        if Map.has_key?(returned_scope, "main") do
          case Map.get(returned_scope, "main") do
            {:function, [], block, fn_scope} ->
              {val, _} = eval_block(block, scope, fn_scope, [])
              val

            _ ->
              raise "RuntimeError: 'main' must be a function, but is not!"
          end
        else
          raise "RuntimeError: 'main' function not found in the program!"
        end

      _ ->
        "Interpreter internal error: Expected program!"
    end
  end

  defp eval_expr_batch([], [runtime_value | _], scope, _), do: {runtime_value, scope}

  defp eval_expr_batch([expression | tail], acc, scope, scope_type) do
    {runtime_value, new_scope} = eval_expr(expression, scope, scope_type)

    case runtime_value do
      # Propagate return immediately
      {:return_value, _} -> {runtime_value, new_scope}
      _ -> eval_expr_batch(tail, [runtime_value | acc], new_scope, scope_type)
    end
  end

  defp eval_expr(expression, scope, scope_type) do
    case expression do
      {:function_declaration, name, arguments, {:block, block}} ->
        new_scope = Map.put(scope, name, {:function, arguments, block, scope})
        {Map.get(new_scope, name), new_scope}

      # Restrict binary operations and assignments to local scopes only
      {:binary_operation, {:operation, _op}, _lhs, _rhs} when scope_type == :global ->
        raise "SyntaxError: Binary operations are not allowed in the global scope!"

      {:assignment_operation, _name, _aexpr} when scope_type == :global ->
        raise "SyntaxError: Variable assignments are not allowed in the global scope!"

      {:integer_literal, _} when scope_type == :global ->
        raise "SyntaxError: Cannot have stuff lingering around, make sure to wrap it inside a function!"

      {:integer_literal, i} ->
        {{:integer_value, i}, scope}

      {:float_literal, _} when scope_type == :global ->
        raise "SyntaxError: Cannot have stuff lingering around, make sure to wrap it inside a function!"

      {:float_literal, i} ->
        {{:float_value, i}, scope}

      {:binary_operation, {:operation, op}, lhs, rhs} ->
        eval_binary_operation(op, lhs, rhs, scope)

      {:assignment_operation, name, aexpr} ->
        {val, _} = eval_expr(aexpr, scope, scope_type)
        new_scope = Map.put(scope, name, val)
        {{:nil_value, nil}, new_scope}

      {:identifier_literal, name} ->
        if Map.has_key?(scope, name) do
          {Map.get(scope, name), scope}
        else
          raise "RuntimeError: Variable #{name} does not exist!"
        end

      {:function_call_operation, name, parameters} ->
        if Map.has_key?(scope, name) do
          {:function, arguments, block, fn_scope} = Map.get(scope, name)

          if Enum.count(arguments) != Enum.count(parameters) do
            raise "Interpreter Error: Function(#{name}), called with different number of arguments!"
          else
            evaluated_params =
              Enum.map(parameters, fn param ->
                {val, _} = eval_expr(param, scope, scope_type)
                val
              end)

            variables = Enum.zip(arguments, evaluated_params)
            fn_scope = Enum.into(variables, make_local_scope(fn_scope))
            {val, new_scope} = eval_block(block, scope, fn_scope, [])

            case val do
              # Return actual value
              {:return_value, inner_val} -> {inner_val, new_scope}
              # Return nil if no explicit return
              _ -> {{:nil_value, nil}, new_scope}
            end
          end
        else
          raise "RuntimeError: Function #{name} isn't defined!"
        end

      {:return_operation, expression} ->
        {val, new_scope} = eval_expr(expression, scope, scope_type)
        # Mark return value
        {{:return_value, val}, new_scope}

      _ ->
        dbg(expression)
        raise "Interpreter internal error: Cannot execute expression!"
    end
  end

  defp eval_block([], parent_scope, _, []), do: {{:nil_value, nil}, parent_scope}
  defp eval_block([], parent_scope, _, [val | _]), do: {val, parent_scope}

  defp eval_block([expression | tail], parent_scope, block_scope, runtime_values) do
    {val, new_scope} = eval_expr(expression, block_scope, :local)
    normalized_scope = Scope.normalize(parent_scope, new_scope)

    case val do
      # Propagate return value immediately
      {:return_value, _} -> {val, normalized_scope}
      _ -> eval_block(tail, normalized_scope, new_scope, [val | runtime_values])
    end
  end

  defp eval_binary_operation(op, lhs, rhs, scope) do
    {lval, _} = eval_expr(lhs, scope, :local)
    {rval, _} = eval_expr(rhs, scope, :local)

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
