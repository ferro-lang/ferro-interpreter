defmodule Interpreter do
  alias Parser

  # Defining runtime types.
  @type runtime_value ::
          {:integer_value, integer()}
          | {:float_value, float()}
          | {:nil_value, nil}
          | {:bool_value, boolean()}
          | {:function, list(String.t()), list(), %{}}
          | {:external_function, String.t(), String.t(), list(String.t()), %{}}
          | {:return_value, runtime_value()}
          | {:string_value, String.t()}

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
              {_, _} = eval_block(block, scope, fn_scope, [])
              nil

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
      {:open_operation, filename} when scope_type == :global ->
        # Defining the path for the standard library
        std_lib_path = "std/ferro/#{filename}.fr"

        # Check whether the file exists
        if File.exists?(std_lib_path) do
          case File.read(std_lib_path) do
            {:ok, content} ->
              case Parser.parse(Lexer.lexer(content)) do
                {:program, imported_expressions} ->
                  {_, imported_scope} = eval_expr_batch(imported_expressions, [], scope, :global)
                  new_scope = Map.merge(scope, imported_scope)
                  {{:nil_value, nil}, new_scope}
              end

            {:error, reason} ->
              raise "Interpreter internal error: #{reason}"
          end
        else
          raise "RuntimeError: Module(#{filename} not found)"
        end

      {:function_declaration, name, arguments, {:block, block}} ->
        new_scope = Map.put(scope, name, {:function, arguments, block, scope})
        {Map.get(new_scope, name), new_scope}

      {:external_function_declaration, elixir_file, elixir_function, function_declaration}
      when scope_type == :global ->
        {_, fname, _, _} = function_declaration
        {fdef, _} = eval_expr(function_declaration, scope, scope_type)

        case fdef do
          {:function, arguments, _, fn_scope} ->
            efdef = {:external_function, elixir_file, elixir_function, arguments, fn_scope}
            new_scope = Map.put(scope, fname, efdef)
            {Map.get(new_scope, fname), new_scope}
        end

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

      {:string_literal, t} ->
        {{:string_value, t}, scope}

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
          case Map.get(scope, name) do
            {:function, arguments, block, fn_scope} ->
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

            {:external_function, elixir_file, elixir_function, arguments, _} ->
              if Enum.count(arguments) != Enum.count(parameters) do
                raise "Interpreter Error: Function(#{name}), called with different number of arguments!"
              else
                elixir_file_path = "std/ex/#{elixir_file}"
                module_name = get_module_name(elixir_file_path)

                if Code.ensure_loaded?(module_name) do
                  module_name
                else
                  case File.read(elixir_file_path) do
                    {:ok, content} ->
                      [{m, _}] = Code.compile_string(content)
                      m

                    {:error, reason} ->
                      {:error, reason}
                  end
                end

                evaluated_params =
                  Enum.map(parameters, fn param ->
                    {val, _} = eval_expr(param, scope, scope_type)
                    extract_value(val)
                  end)

                # Dynamically call the Elixir function
                function_atom = String.to_atom(elixir_function)
                apply(Module.concat(Elixir, module_name), function_atom, evaluated_params)

                {{:nil_value, nil}, scope}
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

  defp get_module_name(file_path) do
    # Assuming that your module name follows a pattern based on the file path,
    # you can extract the module name here. For example:
    # "std/ex/FerroIO.ex" -> FerroIO
    file_path
    |> Path.basename(".ex")
    |> String.to_atom()
  end

  defp extract_value({:integer_value, i}), do: i
  defp extract_value({:float_value, f}), do: f
  defp extract_value({:nil_value, _}), do: nil
  defp extract_value({:bool_value, b}), do: b
  defp extract_value({:string_value, s}), do: s

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
