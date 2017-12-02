defmodule Dlixir do

  def get(lib, uri, opts) do
    file_io = 
      case Keyword.get(opts, :output) do
        nil -> :stdio
        filepath -> 
          {:ok, file_io} = File.open filepath, [:write]
          file_io
      end
    opts = Keyword.delete(opts, :output)

    get_execute(lib, uri, file_io, opts)

    if file_io != :stdio do
      File.close file_io
    end
  end

  defp get_execute(:httpoison, uri, file_io, opts) do
    Dlixir.HTTPoison.get(uri, file_io, opts)
  end 
  defp get_execute(:httpotion, uri, file_io, opts) do
    Dlixir.HTTPotion.get(uri, file_io, opts)
  end 
  defp get_execute(:ibrowse, uri, file_io, opts) do
    Dlixir.IBrowse.get(uri, file_io, opts)
  end 
end
