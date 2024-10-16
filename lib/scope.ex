defmodule Scope do
  def make_global_scope(),
    do: %{true: {:bool_value, true}, false: {:bool_value, false}, nil: {:nil_value, nil}}

  # If the value is a map, clone each key-value pair
  def deepclone(value) when is_map(value) do
    Enum.reduce(value, %{}, fn {key, val}, acc ->
      Map.put(acc, key, deepclone(val))
    end)
  end

  # If the value is a list, clone each element
  def deepclone(value) when is_list(value) do
    Enum.map(value, &deepclone/1)
  end

  # For all other types (non-enumerable), just return the value as is
  def deepclone(value) do
    value
  end

  def normalize(parent_scope, block_scope) do
    Enum.reduce(Map.keys(block_scope), parent_scope, fn key, acc ->
      b_val = Map.get(block_scope, key)

      if Map.has_key?(parent_scope, key) and b_val != Map.get(acc, key) do
        Map.put(acc, key, b_val)
      else
        acc
      end
    end)
  end
end
