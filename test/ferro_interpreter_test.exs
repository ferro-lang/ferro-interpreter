defmodule FerroInterpreterTest do
  use ExUnit.Case
  alias Lexer
  doctest FerroInterpreter

  test "tokenize integers" do
    assert Lexer.lexer("1") == [{:integer, 1}, :eof]
    assert Lexer.lexer("100") == [{:integer, 100}, :eof]
    assert Lexer.lexer("0123456789") == [{:integer, 123_456_789}, :eof]
  end

  test "tokenize (-ve) integers" do
    assert Lexer.lexer("-1") == [{:integer, -1}, :eof]
    assert Lexer.lexer("-99") == [{:integer, -99}, :eof]
    assert Lexer.lexer("-0123456789") == [{:integer, -123_456_789}, :eof]
  end

  test "tokenize float numbers" do
    assert Lexer.lexer("1.0") == [{:float, 1.0}, :eof]
    assert Lexer.lexer("25.0") == [{:float, 25.0}, :eof]
    assert Lexer.lexer("397.0") == [{:float, 397.0}, :eof]
  end

  test "tokenize (-ve) float numbers" do
    assert Lexer.lexer("-1.025") == [{:float, -1.025}, :eof]
    assert Lexer.lexer("-0054.0") == [{:float, -54.0}, :eof]
  end

  test "tokenize operators" do
    assert Lexer.lexer("+ - * / %") == [
             {:operation, :plus},
             {:operation, :minus},
             {:operation, :multiply},
             {:operation, :divide},
             {:operation, :modulus},
             :eof
           ]
  end

  test "parsing numbers" do
    assert Lexer.lexer("54") |> Parser.parse() == {:program, [integer_literal: 54]}
    assert Lexer.lexer("-37.453") |> Parser.parse() == {:program, [float_literal: -37.453]}
  end

  test "parsing single step operations" do
    assert Lexer.lexer("54 + 6") |> Parser.parse() ==
             {:program,
              [
                {:binary_operation, {:operation, :addition}, {:integer_literal, 54},
                 {:integer_literal, 6}}
              ]}

    assert Lexer.lexer("54 - 4") |> Parser.parse() ==
             {:program,
              [
                {:binary_operation, {:operation, :reduction}, {:integer_literal, 54},
                 {:integer_literal, 4}}
              ]}

    assert Lexer.lexer("54 * 5") |> Parser.parse() ==
             {:program,
              [
                {:binary_operation, {:operation, :multiply}, {:integer_literal, 54},
                 {:integer_literal, 5}}
              ]}

    assert Lexer.lexer("54 / 4") |> Parser.parse() ==
             {:program,
              [
                {:binary_operation, {:operation, :divide}, {:integer_literal, 54},
                 {:integer_literal, 4}}
              ]}
  end

  test "parsing multi step operations" do
    assert Lexer.lexer("54 * (8 - 2)") |> Parser.parse() ==
             {:program,
              [
                {:binary_operation, {:operation, :multiply}, {:integer_literal, 54},
                 {:binary_operation, {:operation, :reduction}, {:integer_literal, 8},
                  {:integer_literal, 2}}}
              ]}

    assert Lexer.lexer("26 - 5 / 5") |> Parser.parse() ==
             {:program,
              [
                {:binary_operation, {:operation, :reduction}, {:integer_literal, 26},
                 {:binary_operation, {:operation, :divide}, {:integer_literal, 5},
                  {:integer_literal, 5}}}
              ]}
  end

  test "evaluating expressions" do
    assert Lexer.lexer("5.0") |> Parser.parse() |> Interpreter.eval() == {:float_value, 5.0}
    assert Lexer.lexer("5.0 + 5") |> Parser.parse() |> Interpreter.eval() == {:float_value, 10.0}

    assert Lexer.lexer("25 + 5 - 5") |> Parser.parse() |> Interpreter.eval() ==
             {:integer_value, 25.0}

    assert FerroInterpreter.main("25 - (25 + 25)") == {:integer_value, -25}
    assert FerroInterpreter.main("25 - (25 + 25 / 5 * 10)") == {:float_value, -0.5}
  end
end
