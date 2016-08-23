defmodule Raven.MeterSupervisor do
    use Supervisor
    require Logger

    def start_link do
        Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    end

    def init(:ok) do
        children = [
            worker(Raven.Meter, [], restart: :transient)
        ]
        supervise(children, strategy: :simple_one_for_one)
    end

    def start_meter(meter_mac_id) do
        Logger.info "Starting meter #{meter_mac_id}"
        Supervisor.start_child(__MODULE__, [String.to_atom(meter_mac_id)])
    end
end
