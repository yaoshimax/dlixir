defmodule Dlixir.HTTPotion do
  def get(uri, file_io, opts) do
    httpotion_opts = 
      case Keyword.get(opts, :once) do
        true -> [ibrowse: [stream_to: {self, :once}], timeout: :infinity]
        _ -> [stream_to: self, timeout: :infinity]
      end
    internal_opts = 
      case Keyword.get(opts, :buffersize) do
        nil -> opts ++ [buffersize: 0]
        _val -> opts
      end

    case HTTPotion.get uri, httpotion_opts do
      %HTTPotion.AsyncResponse{id: req_id} ->
        case Keyword.get(opts, :once) do
          true -> Dlixir.IBrowse.message_receive(file_io, <<>>, internal_opts, req_id)
          _ -> message_receive(file_io, <<>>, internal_opts, req_id)
        end
      error -> 
        :io.format "request failed ~p", [error]
    end
  end

  def message_receive(file_io, buffer, opts, req_id) do
    buffersize = Keyword.get(opts, :buffersize)
    receive do
      %HTTPotion.AsyncHeaders{status_code: 200} -> message_receive(file_io, buffer, opts, req_id)
      %HTTPotion.AsyncChunk{chunk: chunk} -> 
        buffer = 
          case byte_size(chunk) + byte_size(buffer) > buffersize do
            true -> 
              IO.binwrite(file_io, buffer)
              <<>>
            false -> 
              buffer
          end
          message_receive(file_io, buffer <> chunk, opts, req_id)
      %HTTPotion.AsyncEnd{id: _req_id} ->
        IO.binwrite(file_io, buffer)
        IO.write("finished!")
      invalid_message -> 
        :io.format "invalid_messagee ~p", [invalid_message]
    end
  end
end
