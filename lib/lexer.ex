defmodule Lexer do
  # Defining the operators as atoms.
  @type operator ::
          :plus | :minus | :multiply | :divide | :modulus

  # Defining the token types.
  @type token ::
          :eof
          | :let
          | :lparen
          | :rparen
          | :assignment
          | {:integer, integer()}
          | {:float, float()}
          | {:identifier, String.t()}
          | {:string, String.t()}
          | {:operation, operator()}

  # Converting character to operator atom.
  defp operator_from_character(?+), do: :plus
  defp operator_from_character(?-), do: :minus
  defp operator_from_character(?*), do: :multiply
  defp operator_from_character(?/), do: :divide
  defp operator_from_character(?%), do: :modulus

  # Function that is used to typehint the given number to 
  # two classified categories of integer or float.
  defp get_number_atom(number_list) do
    {string_version, is_classified_float} =
      Enum.reduce(number_list, {"", false}, fn
        ".", {acc, _} -> {acc <> ".", true}
        digit, {acc, is_classified_float} -> {acc <> digit, is_classified_float}
      end)

    if is_classified_float do
      {:float, String.to_float(string_version)}
    else
      {:integer, String.to_integer(string_version)}
    end
  end

  defp get_identifier_atom(identifier) do
    case identifier do
      "let" -> :let
      _ -> {:identifier, identifier}
    end
  end

  defguardp is_valid_identifier_character(char)
            when char in [
                   "a",
                   "b",
                   "c",
                   "d",
                   "e",
                   "f",
                   "g",
                   "h",
                   "i",
                   "j",
                   "k",
                   "l",
                   "m",
                   "n",
                   "o",
                   "p",
                   "q",
                   "r",
                   "s",
                   "t",
                   "u",
                   "v",
                   "w",
                   "x",
                   "y",
                   "z",
                   "A",
                   "B",
                   "C",
                   "D",
                   "E",
                   "F",
                   "G",
                   "H",
                   "I",
                   "J",
                   "K",
                   "L",
                   "M",
                   "N",
                   "O",
                   "P",
                   "Q",
                   "R",
                   "S",
                   "T",
                   "U",
                   "V",
                   "W",
                   "X",
                   "Y",
                   "Z",
                   "0",
                   "1",
                   "2",
                   "3",
                   "4",
                   "5",
                   "6",
                   "7",
                   "8",
                   "9"
                 ]

  # Main Lexer logic.
  def lexer(source) do
    helper(String.graphemes(source), [])
  end

  # Helper function to tokenize the source.
  defp helper([], tokens), do: Enum.reverse([:eof | tokens])

  defp helper([char | tail], tokens) do
    case char do
      "=" ->
        helper(tail, [:assignment | tokens])

      "(" ->
        helper(tail, [:lparen | tokens])

      ")" ->
        helper(tail, [:rparen | tokens])

      "+" ->
        helper(tail, [{:operation, operator_from_character(?+)} | tokens])

      "*" ->
        helper(tail, [{:operation, operator_from_character(?*)} | tokens])

      "/" ->
        helper(tail, [{:operation, operator_from_character(?/)} | tokens])

      "%" ->
        helper(tail, [{:operation, operator_from_character(?%)} | tokens])

      # Handing the minus case seperately, as (-ve) numbers also start with '-'
      "-" ->
        extract_minus_or_number(tail, tokens)

      # Handing positive numbers
      _ when char in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"] ->
        extract_number([], [char | tail], tokens)

      # Handing Identifiers
      _
      when is_valid_identifier_character(char) ->
        extract_identifier([char], tail, tokens)

      # Skipping whitespace
      _ when char in [" ", "\n", "\r", "\t"] ->
        helper(tail, tokens)

      _ ->
        raise "Lexer error: Encountered Unexpected character, got #{char}"
    end
  end

  # Function to handle cases where the potential next tokens is a numbers
  # or a minus as both contains a (-) sign in the begining.
  defp extract_minus_or_number(chars, tokens) do
    case chars do
      [char | _] when char in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"] ->
        extract_number(["-"], chars, tokens)

      _ ->
        helper(chars, [{:operation, operator_from_character(?-)} | tokens])
    end
  end

  # Function to extract number from a character list.
  defp extract_number(acc, [], tokens),
    do: helper([], [get_number_atom(Enum.reverse(acc)) | tokens])

  defp extract_number(acc, [char | tail], tokens) do
    case char do
      _ when char in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "."] ->
        extract_number([char | acc], tail, tokens)

      _ ->
        helper([char | tail], [get_number_atom(Enum.reverse(acc)) | tokens])
    end
  end

  defp extract_identifier(acc, [], tokens),
    do: helper([], [get_identifier_atom(Enum.reverse(acc) |> Enum.join("")) | tokens])

  defp extract_identifier(acc, [char | tail], tokens) do
    case char do
      _ when is_valid_identifier_character(char) ->
        extract_identifier([char | acc], tail, tokens)

      _ ->
        helper([char | tail], [get_identifier_atom(Enum.reverse(acc) |> Enum.join("")) | tokens])
    end
  end
end
