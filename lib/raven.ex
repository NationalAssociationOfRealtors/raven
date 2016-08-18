defmodule Raven do
    use Application
    require Logger

    defmodule Event do
        defstruct [:code, :message]
    end

    def start(_type, _args) do
        Raven.Supervisor.start_link
    end
end
