defmodule FerroInterpreter do
  def main(source) do
    source
    |> Lexer.lexer()
    |> Parser.parse()
    |> Interpreter.eval(Scope.make_global_scope())

    nil
  end

  def file(filename) do
    {:ok, content} = File.read("source/#{filename}.fr")
    Scope.make_global_scope() |> eval(content)
  end

  defp eval(scope, content) do
    Interpreter.eval(
      Parser.parse(Lexer.lexer(content)),
      scope
    )
  end
end
