defmodule Raven.Parser do
    use GenServer
    alias Raven.Message

    @message_signatures Application.get_env(:raven, :message_signatures)
    @message_keys Application.get_env(:raven, :message_keys)

    def start_link() do
        GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    end

    def parse(parser, payload) do
        GenServer.call(parser, {:parse, payload})
    end

    def handle_call({:parse, payload}, _from, state) do
        {:reply, Enum.reduce(@message_keys, %{}, fn(key, message) ->
            case String.ends_with?(payload, key) do
                true ->
                    Map.merge(
                        message,
                        @message_signatures[String.to_existing_atom(key)].parse(payload)
                    )
                _ -> message
            end
        end), state}
    end
end
