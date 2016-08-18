defmodule Raven.Handler do
    use GenEvent
    alias Raven.Event
    require Logger

    def init(parent) do
        {:ok, parent}
    end

    def handle_event(%Event{} = event, parent) do
        Logger.debug "#{inspect event}"
        send(parent, event)
        {:ok, parent}
    end
end
