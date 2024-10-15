defmodule FerroInterpreter do
  def main(source), do: Interpreter.eval(Parser.parse(Lexer.lexer(source)))
end
