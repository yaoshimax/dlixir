defmodule Dlixir.HTTPoison do
  def get(uri, file_io, opts) do
    httpoison_opts = 
      case Keyword.get(opts, :once) do
        true -> [stream_to: self, async: :once]
        _ -> [stream_to: self]
      end
    internal_opts = 
      case Keyword.get(opts, :buffersize) do
        nil -> opts ++ [buffersize: 0]
        _val -> opts
      end

    case HTTPoison.get uri, %{}, httpoison_opts do
      {:ok, resp = %HTTPoison.AsyncResponse{id: _id}} ->
          message_receive(file_io, <<>>, internal_opts, resp)
      error -> 
        :io.format "request failed ~p", [error]
    end
  end

  def message_receive(file_io, buffer, opts, resp) do
    buffersize = Keyword.get(opts, :buffersize)
    receive do
      %HTTPoison.AsyncStatus{code: 200} -> next_message_receive(file_io, buffer, opts, resp)
      %HTTPoison.AsyncHeaders{} -> next_message_receive(file_io, buffer, opts, resp)
      %HTTPoison.AsyncChunk{chunk: chunk} -> 
        buffer = 
          case byte_size(chunk) + byte_size(buffer) > buffersize do
            true -> 
              IO.binwrite(file_io, buffer)
              <<>>
            false -> 
              buffer
          end
        next_message_receive(file_io, buffer <> chunk, opts, resp)
      %HTTPoison.AsyncEnd{id: _id} ->
        IO.binwrite(file_io, buffer)
        IO.write("finished!")
      invalid_message -> 
        :io.format "invalid_messagee ~p", [invalid_message]
    end
  end

  def next_message_receive(file_io, buffer, opts, resp) do
    if Keyword.get(opts, :once) do
      {:ok, ^resp} = HTTPoison.stream_next(resp)
    end
    message_receive(file_io, buffer, opts, resp)
  end
end
