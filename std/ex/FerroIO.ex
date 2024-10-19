defmodule FerroIO do
  @moduledoc """
  This module provides standard input/output operations for Ferro.
  """

  @doc """
  Prints the given argument to the console with a newline.
  """
  def println(arg), do: IO.puts(arg)

  @doc """
  Prints the given argument to the console without a newline.
  """
  def print(arg), do: IO.write(arg)

  @doc """
  Reads a line of input from the console.
  """
  def read_line, do: IO.gets("")

  @doc """
  Reads a single character from the console.
  """
  def read_char do
    <<char::utf8>> = IO.getn("", 1)
    char
  end

  @doc """
  Flushes the console output.
  """
  def flush, do: IO.write(:stdio, "")

  @doc """
  Clears the console screen.
  """
  def clear_screen, do: IO.write(:stdio, "\e[2J\e[H")

  @doc """
  Writes the given content to a file.
  """
  def write_file(filename, content) do
    File.write(filename, content)
  end

  @doc """
  Reads the content of a file.
  """
  def read_file(filename) do
    case File.read(filename) do
      {:ok, content} -> content
      {:error, reason} -> raise "Error reading file: #{reason}"
    end
  end

  @doc """
  Appends content to an existing file.
  """
  def append_file(filename, content) do
    File.write(filename, content, [:append])
  end

  @doc """
  Checks if a file exists.
  """
  def file_exists?(filename), do: File.exists?(filename)

  @doc """
  Deletes a file.
  """
  def delete_file(filename) do
    case File.rm(filename) do
      :ok -> :ok
      {:error, reason} -> raise "Error deleting file: #{reason}"
    end
  end

  @doc """
  Creates a directory.
  """
  def create_directory(path) do
    case File.mkdir(path) do
      :ok -> :ok
      {:error, reason} -> raise "Error creating directory: #{reason}"
    end
  end

  @doc """
  Lists the contents of a directory.
  """
  def list_directory(path) do
    case File.ls(path) do
      {:ok, files} -> files
      {:error, reason} -> raise "Error listing directory: #{reason}"
    end
  end

  @doc """
  Evaluates the code
  """
  def eval_code(code) do
    FerroInterpreter.main("fn main() {#{code}}")
  end
end
