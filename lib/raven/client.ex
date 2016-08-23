defmodule Raven.Client do
    use GenServer
    require Logger
    alias Raven.Message
    alias Nerves.UART, as: Serial
    alias Raven.Client.MessageSupervisor

    @message_signatures Application.get_env(:raven, :message_signatures)
    @message_keys Application.get_env(:raven, :message_keys)

    defmodule State do
        defstruct meters: [],
            network_info: %Message.NetworkInfo{},
            message: "",
            events: nil,
            handlers: []
    end

    def start_link() do
        GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    end

    def add_handler(handler) do
        GenServer.call(__MODULE__, {:handler, handler})
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
        {:ok, events} = GenEvent.start_link([{:name, Raven.Events}])
        Logger.debug "Starting Serial: #{tty}"
        Serial.configure(Raven.Serial, framing: {Serial.Framing.Line, separator: "\r\n"})
        Serial.open(Raven.Serial, tty, speed: speed, active: true)
        Logger.info "Running"
        Process.send_after(self(), :get_meters, 100)
        {:ok, %State{:events => events}}
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

    def handle_cast(:schedule_info, state) do
        Serial.write(Raven.Serial, Message.ScheduleInfo.command)
        {:noreply, state}
    end

    def handle_cast(:meter_info, state) do
        Serial.write(Raven.Serial, Message.MeterInfo.command)
        {:noreply, state}
    end

    def handle_cast(:network_info, state) do
        Serial.write(Raven.Serial, Message.NetworkInfo.command)
        {:noreply, state}
    end

    def handle_cast(:get_time, state) do
        Serial.write(Raven.Serial, Message.TimeCluster.command)
        {:noreply, state}
    end

    def handle_cast(:get_message, state) do
        Serial.write(Raven.Serial, Message.MessageCluster.command)
        {:noreply, state}
    end

    def handle_cast(:get_price, state) do
        Serial.write(Raven.Serial, Message.PriceCluster.command)
        {:noreply, state}
    end

    def handle_cast(:get_demand, state) do
        Serial.write(Raven.Serial, Message.InstantaneousDemand.command)
        {:noreply, state}
    end

    def handle_cast(:get_summation, state) do
        Serial.write(Raven.Serial, Message.CurrentSummationDelivered.command)
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

    def handle_call({:handler, handler}, {pid, _} = from, state) do
        GenEvent.add_mon_handler(state.events, handler, pid)
        {:reply, :ok, %{state | :handlers => [{handler, pid} | state.handlers]}}
    end

    def handle_info(:get_meters, state) do
        meters()
        {:noreply, state}
    end

    def handle_info({:gen_event_EXIT, handler, reason}, state) do
        Enum.each(state.handlers, fn(h) ->
            GenEvent.add_mon_handler(state.events, elem(h, 0), elem(h, 1))
        end)
        {:noreply, state}
    end

    def handle_info({:nerves_uart, _serial, {:partial, data}}, state) do
        {:noreply, state}
    end

    def handle_info({:nerves_uart, _serial, data}, state) do
        message = state.message <> data
        {:noreply,
            case String.ends_with?(String.trim(message), @message_keys) do
                true ->
                    %State{
                        Raven.Parser.parse(Raven.Parser, message)
                        |> handle_message(state) | :message => ""
                    }
                _ -> %State{state | :message => message}
            end
        }
    end

    def handle_message(%Message.MeterList{} = message, state) do
        Enum.each(message.meters, fn(meter) ->
            case Process.whereis(String.to_atom(meter)) do
                nil -> Raven.MeterSupervisor.start_meter(meter)
                _ -> true
            end
        end)
        %State{state | :meters => Enum.uniq(message.meters ++ state.meters)}
    end

    def handle_message(message, state) do
        Logger.debug("Received Message: #{inspect message}")
        state
    end

end
