defmodule FerroInterpreter do
  def main(source),
    do:
      source
      |> Lexer.lexer()
      |> Parser.parse()
      |> Interpreter.eval(Interpreter.make_global_scope())

  def file(filename) do
    {:ok, content} = File.read("source/#{filename}.fr")
    Interpreter.make_global_scope() |> eval(content)
  end

  defp eval(scope, content) do
    Interpreter.eval(
      Parser.parse(Lexer.lexer(content)),
      scope
    )
  end
end
