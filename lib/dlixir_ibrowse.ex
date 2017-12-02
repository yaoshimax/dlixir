defmodule Dlixir.IBrowse do
  def get(uri, file_io, opts) do
    ibrowse_opts = 
      case Keyword.get(opts, :once) do
        true -> [stream_to: {self, :once}]
        _ -> [stream_to: self]
      end
    internal_opts = 
      case Keyword.get(opts, :buffersize) do
        nil -> opts ++ [buffersize: 0]
        _val -> opts
      end

    uri_charlist = to_charlist uri
    case :ibrowse.send_req uri_charlist, [], :get, [], ibrowse_opts, :infinity do
      {:ibrowse_req_id, req_id} ->
        message_receive(file_io, <<>>, internal_opts, req_id)
      error -> 
        :io.format "request failed ~p", [error]
    end
  end

  def message_receive(file_io, buffer, opts, req_id) do
    if Keyword.get(opts, :once) do
      :ok = :ibrowse.stream_next(req_id)
    end
    buffersize = Keyword.get(opts, :buffersize)
    receive do
      {:ibrowse_async_headers, ^req_id, '200', _headers} 
        -> message_receive(file_io, buffer, opts, req_id)
      {:ibrowse_async_response, ^req_id, error = {:error, _}} -> 
        :io.format "error response ~p", [error]
      {:ibrowse_async_response, ^req_id, chunk} -> 
        chunk = to_string chunk
        buffer = 
          case byte_size(chunk) + byte_size(buffer) > buffersize do
            true -> 
              IO.binwrite(file_io, buffer)
              <<>>
            false -> 
              buffer
          end
          message_receive(file_io, buffer <> chunk, opts, req_id)
      {:ibrowse_async_response_end, ^req_id} ->
        IO.binwrite(file_io, buffer)
        IO.write("finished!")
      invalid_message -> 
        :io.format "invalid_messagee ~p", [invalid_message]
    end
  end
end
