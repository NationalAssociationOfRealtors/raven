defmodule Raven.Meter do
    use GenServer
    require Logger
    alias Raven.Message

    defmodule State do
        defstruct id: nil,
            meter_info: %Message.MeterInfo{},
            connection_status: %Message.ConnectionStatus{},
            time: %Message.TimeCluster{},
            message: %Message.MessageCluster{},
            price: %Message.PriceCluster{},
            demand: %Message.InstantaneousDemand{},
            summation: %Message.CurrentSummationDelivered{},
            schedules: %{
                time: %Message.ScheduleInfo{},
                price: %Message.ScheduleInfo{},
                demand: %Message.ScheduleInfo{},
                summation: %Message.ScheduleInfo{},
                message: %Message.ScheduleInfo{}
            }
    end

    def start_link(id) do
        GenServer.start_link(__MODULE__, id, name: id)
    end

    def init(id) do
        Logger.debug("Started Meter: #{inspect id}")
        {:ok, %State{id: id}}
    end

    def handle_cast({:message, %Message.MeterInfo{} = message}, state) do
        {:noreply, %State{state | :meter_info => message}}
    end

    def handle_cast({:message, %Message.ConnectionStatus{} = message}, state) do
        {:noreply, %State{state | :connection_status => message}}
    end

    def handle_cast({:message, %Message.TimeCluster{} = message}, state) do
        {:noreply, %State{state | :time => message}}
    end

    def handle_cast({:message, %Message.MessageCluster{} = message}, state) do
        {:noreply, %State{state | :message => message}}
    end

    def handle_cast({:message, %Message.PriceCluster{} = message}, state) do
        {:noreply, %State{state | :price => message}}
    end

    def handle_cast({:message, %Message.InstantaneousDemand{} = message}, state) do
        {:noreply, %State{state | :demand => message}}
    end

    def handle_cast({:message, %Message.CurrentSummationDelivered{} = message}, state) do
        {:noreply, %State{state | :summation => message}}
    end

    def handle_cast({:message, %Message.ScheduleInfo{} = message}, state) do
        {:noreply, %State{state | :schedules => %{state.schedules |
            String.to_existing_atom(Map.get(message, :event)) => message
        }}}
    end

    def handle_cast({:message, message}, state) do
        Logger.info("Meter #{inspect state.id} Message: #{inspect message}")
        {:noreply, state}
    end

end
