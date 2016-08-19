defmodule Raven do
    use Application
    require Logger

    def start(_type, _args) do
        Raven.Supervisor.start_link
    end
end
