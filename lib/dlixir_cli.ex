defmodule Dlixir.CLI do
  def main(args) do
    args |> parse_args |> do_process
  end

  def parse_args(args) do
    parsed_args = OptionParser.parse(args, switches: [help: :boolean, buffersize: :integer, once: :boolean], aliases: [l: :lib, u: :uri, o: :output, b: :buffersize])
    case parsed_args do 
      {[help: true], _, _} -> :help
      {opts, _, _} ->
        cond do
          Keyword.has_key?(opts, :lib) and Keyword.has_key?(opts, :uri) -> 
            lib = String.to_atom(Keyword.get(opts, :lib))
            uri = Keyword.get(opts, :uri)
            opts = Keyword.delete(Keyword.delete(opts, :lib), :uri)
            {lib, uri, opts}
          true -> 
            :help
        end
    end
  end

  def do_process({lib, uri, opts}) do
    Dlixir.get(lib, uri, opts)
  end
  def do_process(:help) do
    IO.puts "Usage: ./dlixir -l httpoison|httpotion -u http://xxx [-o filepath] [-b buffersize]"
  end

end
