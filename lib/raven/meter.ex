defmodule Raven.Meter do
    use GenServer
    require Logger
    alias Raven.Message
    alias Nerves.UART, as: Serial

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
        {:ok, %State{id: id}}
    end

end
