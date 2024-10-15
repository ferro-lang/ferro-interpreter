defmodule Interpreter do
  alias Parser

  # Defining the runtime types.
  @type runtime_value ::
          {:integer_value, integer()}
          | {:float_value, float()}
          | {:nil_value, nil}

  # Main Interpreter logic.
  def eval({:program, []}), do: {:nil_value, nil}
  def eval(program), do: eval(program, [])

  defp eval(program, acc) do
    case program do
      {:program, expressions} -> eval_expr_batch(expressions, acc)
      _ -> "Interpreter internal error: Expected program, got #{program}"
    end
  end

  defp eval_expr_batch([], [runtime_value | _]), do: runtime_value

  defp eval_expr_batch([expression | tail], acc) do
    eval_expr_batch(tail, [eval_expr(expression) | acc])
  end

  defp eval_expr(expression) do
    case expression do
      {:integer_literal, i} ->
        {:integer_value, i}

      {:float_literal, i} ->
        {:float_value, i}

      {:binary_operation, {:operation, op}, lhs, rhs} ->
        eval_binary_operation(op, lhs, rhs)

      [expression | _] ->
        raise "Interpreter internal error: Interpreter, is not capable of exectuing the following expressiong, got #{expression}"
    end
  end

  defp eval_binary_operation(op, lhs, rhs) do
    lval = eval_expr(lhs)
    rval = eval_expr(rhs)

    apply_operation(op, lval, rval)
  end

  defp apply_operation(op, {:integer_value, li}, {:integer_value, ri}),
    do: eval_operation(op, li, ri, :integer_value)

  defp apply_operation(op, {:float_value, li}, {:integer_value, ri}),
    do: eval_operation(op, li, ri, :float_value)

  defp apply_operation(op, {:integer_value, li}, {:float_value, ri}),
    do: eval_operation(op, li, ri, :float_value)

  defp apply_operation(op, {:float_value, li}, {:float_value, ri}),
    do: eval_operation(op, li, ri, :float_value)

  defp apply_operation(op, _, _),
    do: raise("Interpreter error: Unsupported operation(#{op})!")

  defp eval_operation(:addition, li, ri, atom), do: {atom, li + ri}
  defp eval_operation(:reduction, li, ri, atom), do: {atom, li - ri}
  defp eval_operation(:multiply, li, ri, atom), do: {atom, li * ri}
  defp eval_operation(:divide, li, ri, _), do: {:float_value, li / ri}

  defp eval_operation(:modulus, _, _, _),
    do: raise("Interpreter internal error: Modulus operations are currently beyond capability.")
end
