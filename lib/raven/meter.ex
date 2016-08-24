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
                message: %Message.ScheduleInfo{},
                profile_data: %Message.ScheduleInfo{},
                scheduled_prices: %Message.ScheduleInfo{}
            }
    end

    def start_link(id) do
        GenServer.start_link(__MODULE__, id, name: id)
    end

    def init(id) do
        Logger.debug("Started Meter: #{inspect id}")
        Process.send_after(self, :update, 1000)
        {:ok, %State{id: id}}
    end

    def handle_info(:update, state) do
        Raven.Client.connection_status
        Raven.Client.schedule_info(state.id)
        Raven.Client.meter_info(state.id)
        Raven.Client.get_time(state.id)
        Raven.Client.get_message(state.id)
        Raven.Client.get_price(state.id)
        Raven.Client.get_demand(state.id)
        Raven.Client.get_summation(state.id)
        Process.send_after(self, :update, 10000)
        {:noreply, state}
    end

    def handle_cast({:message, %Message.MeterInfo{} = message}, state) do
        state = %State{state | :meter_info => message}
        GenEvent.notify(Raven.Events, state)
        {:noreply, state}
    end

    def handle_cast({:message, %Message.ConnectionStatus{} = message}, state) do
        state = %State{state | :connection_status => message}
        GenEvent.notify(Raven.Events, state)
        {:noreply, state}
    end

    def handle_cast({:message, %Message.TimeCluster{} = message}, state) do
        state = %State{state | :time => message}
        GenEvent.notify(Raven.Events, state)
        {:noreply, state}
    end

    def handle_cast({:message, %Message.MessageCluster{} = message}, state) do
        state = %State{state | :message => message}
        GenEvent.notify(Raven.Events, state)
        {:noreply, state}
    end

    def handle_cast({:message, %Message.PriceCluster{} = message}, state) do
        state = %State{state | :price => message}
        GenEvent.notify(Raven.Events, state)
        {:noreply, state}
    end

    def handle_cast({:message, %Message.InstantaneousDemand{} = message}, state) do
        state = %State{state | :demand => message}
        GenEvent.notify(Raven.Events, state)
        {:noreply, state}
    end

    def handle_cast({:message, %Message.CurrentSummationDelivered{} = message}, state) do
        state = %State{state | :summation => message}
        GenEvent.notify(Raven.Events, state)
        {:noreply, state}
    end

    def handle_cast({:message, %Message.ScheduleInfo{} = message}, state) do
        state = %State{state | :schedules => %{state.schedules |
            String.to_existing_atom(Map.get(message, :event)) => message
        }}
        GenEvent.notify(Raven.Events, state)
        {:noreply, state}
    end

    def handle_cast({:message, message}, state) do
        Logger.error("Unknown message type for Meter #{inspect state.id} Message: #{inspect message}")
        {:noreply, state}
    end

end
