defmodule Raven.Handler do
    use GenEvent
    require Logger

    def init(parent) do
        {:ok, parent}
    end

    def handle_event(event, parent) do
        Logger.debug "#{inspect event}"
        send(parent, event)
        {:ok, parent}
    end
end
