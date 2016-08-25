defmodule Raven.Client do
    use GenServer
    require Logger
    alias Raven.Message
    alias Nerves.UART, as: Serial
    alias Raven.Client.MessageSupervisor

    @message_signatures Application.get_env(:raven, :message_signatures)

    defmodule State do
        defstruct meters: [],
            network_info: %Message.NetworkInfo{},
            device_info: %Message.DeviceInfo{},
            message: "",
            events: nil
    end

    def start_link() do
        GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    end

    def meters() do
        GenServer.cast(__MODULE__, :meters)
    end

    def connection_status() do
        GenServer.cast(__MODULE__, :connection_status)
    end

    def device_info() do
        GenServer.cast(__MODULE__, :device_info)
    end

    def network_info() do
        GenServer.cast(__MODULE__, :network_info)
    end

    def schedule_info(meter_mac_id) do
        GenServer.cast(__MODULE__, {:schedule_info, meter_mac_id})
    end

    def meter_info(meter_mac_id) do
        GenServer.cast(__MODULE__, {:meter_info, meter_mac_id})
    end

    def get_time(meter_mac_id) do
        GenServer.cast(__MODULE__, {:get_time, meter_mac_id})
    end

    def get_message(meter_mac_id) do
        GenServer.cast(__MODULE__, {:get_message, meter_mac_id})
    end

    def get_price(meter_mac_id) do
        GenServer.cast(__MODULE__, {:get_price, meter_mac_id})
    end

    def get_demand(meter_mac_id) do
        GenServer.cast(__MODULE__, {:get_demand, meter_mac_id})
    end

    def get_summation(meter_mac_id) do
        GenServer.cast(__MODULE__, {:get_summation, meter_mac_id})
    end

    def initialize() do
        GenServer.cast(__MODULE__, :initialize)
    end

    def restart() do
        GenServer.cast(__MODULE__, :restart)
    end

    def factory_reset() do
        GenServer.cast(__MODULE__, :factory_reset)
    end

    def init(:ok) do
        tty = Application.get_env(:raven, :tty)
        speed = Application.get_env(:raven, :speed)
        {:ok, serial} = Serial.start_link([{:name, Raven.Serial}])
        Logger.debug "Starting Serial: #{tty}"
        Serial.configure(Raven.Serial, framing: {Serial.Framing.Line, separator: "\r\n"})
        Serial.open(Raven.Serial, tty, speed: speed, active: true)
        Logger.info "Running"
        Process.send_after(self(), :update, 1000)
        {:ok, %State{}}
    end

    def handle_cast(:meters, state) do
        Serial.write(Raven.Serial, Message.MeterList.command)
        {:noreply, state}
    end

    def handle_cast(:connection_status, state) do
        Serial.write(Raven.Serial, Message.ConnectionStatus.command)
        {:noreply, state}
    end

    def handle_cast(:device_info, state) do
        Serial.write(Raven.Serial, Message.DeviceInfo.command)
        {:noreply, state}
    end

    def handle_cast(:network_info, state) do
        Serial.write(Raven.Serial, Message.NetworkInfo.command)
        {:noreply, state}
    end

    def handle_cast({:schedule_info, meter_mac_id}, state) do
        Serial.write(Raven.Serial, Message.ScheduleInfo.command(meter_mac_id))
        {:noreply, state}
    end

    def handle_cast({:meter_info, meter_mac_id}, state) do
        Serial.write(Raven.Serial, Message.MeterInfo.command(meter_mac_id))
        {:noreply, state}
    end

    def handle_cast({:get_time, meter_mac_id}, state) do
        Serial.write(Raven.Serial, Message.TimeCluster.command(meter_mac_id))
        {:noreply, state}
    end

    def handle_cast({:get_message, meter_mac_id}, state) do
        Serial.write(Raven.Serial, Message.MessageCluster.command(meter_mac_id))
        {:noreply, state}
    end

    def handle_cast({:get_price, meter_mac_id}, state) do
        Serial.write(Raven.Serial, Message.PriceCluster.command(meter_mac_id))
        {:noreply, state}
    end

    def handle_cast({:get_demand, meter_mac_id}, state) do
        Serial.write(Raven.Serial, Message.InstantaneousDemand.command(meter_mac_id))
        {:noreply, state}
    end

    def handle_cast({:get_summation, meter_mac_id}, state) do
        Serial.write(Raven.Serial, Message.CurrentSummationDelivered.command(meter_mac_id))
        {:noreply, state}
    end

    def handle_cast(:initialize, state) do
        Serial.write(Raven.Serial, Message.Initialize.command)
        {:noreply, state}
    end

    def handle_cast(:restart, state) do
        Serial.write(Raven.Serial, Message.Restart.command)
        {:noreply, state}
    end

    def handle_cast(:factory_reset, state) do
        Serial.write(Raven.Serial, Message.FactoryReset.command)
        {:noreply, state}
    end

    def handle_info(:update, state) do
        meters()
        device_info()
        network_info()
        Process.send_after(self(), :update, 10000)
        {:noreply, state}
    end

    def handle_info({:nerves_uart, _serial, {:partial, data}}, state) do
        {:noreply, state}
    end

    def handle_info({:nerves_uart, _serial, data}, state) do
        message = state.message <> data |> String.trim
        {:noreply, Enum.reduce(Map.keys(@message_signatures), state, fn(tag, state) ->
            ts = tag |> Atom.to_string
            with true <- String.starts_with?(message, "<#{ts}>"),
                true <- String.ends_with?(message, "</#{ts}>") do
                %State{
                    @message_signatures[tag].parse(message)
                    |> handle_message(state) | :message => ""
                }
            else
                false -> %State{state | :message => message}
            end
        end)}
    end

    def handle_message(%Message.MeterList{} = message, state) do
        Enum.each(message.meters, fn(meter) ->
            case Process.whereis(String.to_atom(meter)) do
                nil -> Raven.MeterSupervisor.start_meter(meter)
                _ -> true
            end
        end)
        state = %State{state | :meters => Enum.uniq(message.meters ++ state.meters)}
        GenEvent.notify(Raven.Events, state)
        state
    end

    def handle_message(%Message.DeviceInfo{} = message, state) do
        state = %State{state | :device_info => message}
        GenEvent.notify(Raven.Events, state)
        state
    end

    def handle_message(%Message.NetworkInfo{} = message, state) do
        state = %State{state | :network_info => message}
        GenEvent.notify(Raven.Events, state)
        state
    end

    def handle_message(message, state) do
        case Map.get(message, :meter_mac_id) do
            nil -> nil
            _ -> GenServer.cast(String.to_atom(message.meter_mac_id), {:message, message})
        end
        state
    end

end
