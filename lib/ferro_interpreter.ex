defmodule FerroInterpreter do
  def main(source) do
    source
    |> Lexer.lexer()
    |> Parser.parse()
    |> Interpreter.eval(Scope.make_global_scope())
  end

  def file(filename) do
    {seconds, _} =
      :timer.tc(fn ->
        {:ok, content} = File.read("source/#{filename}.fr")
        Scope.make_global_scope() |> eval(content)
      end)

    IO.puts("Time: #{seconds / 1_000_000}")
  end

  defp eval(scope, content) do
    Interpreter.eval(
      Parser.parse(Lexer.lexer(content)),
      scope
    )
  end
end
