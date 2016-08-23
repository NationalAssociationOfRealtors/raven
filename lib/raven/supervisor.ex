defmodule Raven.Supervisor do
    use Supervisor

    def start_link do
        Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    end

    def init(:ok) do
        children = [
            worker(Raven.Client, []),
            worker(Raven.Parser, []),
            supervisor(Raven.MeterSupervisor, []),
        ]
        supervise(children, strategy: :one_for_one)
    end
end
