defmodule Raven.Client do
    use GenServer
    require Logger
    alias Raven.Event
    alias Raven.Message
    alias Nerves.UART, as: Serial
    alias Raven.Client.MessageSupervisor

    @message_signatures %{
        "</InstantaneousDemand>": Message.InstantaneousDemand,
        "</PriceCluster>": Message.PriceCluster
    }

    @message_keys Enum.map(Map.keys(@message_signatures), fn(k) -> Atom.to_string(k) end)

    def start_link() do
        GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    end

    def add_handler(handler) do
        GenServer.call(__MODULE__, {:handler, handler})
    end

    def status() do
        GenServer.cast(__MODULE__, :status)
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
        {:ok, %{:message => "", :events => events, :handlers => []}}
    end

    def handle_cast(:status, state) do
        Serial.write(Raven.Serial, Message.ConnectionStatus.command)
        {:noreply, state}
    end

    def handle_call({:handler, handler}, {pid, _} = from, state) do
        GenEvent.add_mon_handler(state.events, handler, pid)
        {:reply, :ok, %{state | :handlers => [{handler, pid} | state.handlers]}}
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
        new_state = %{state | :message => state.message <> data}
        new_state =
            case String.ends_with?(String.trim(new_state.message), @message_keys) do
                true ->
                    handle_message(new_state.message)
                    %{new_state | :message => ""}
                _ -> new_state
            end
        {:noreply, new_state}
    end

    def handle_message(message) do
        Enum.each(@message_keys, fn(key) ->
            case String.ends_with?(message, key) do
                true ->
                    Logger.info("Processing Message #{message}")
                    Task.Supervisor.start_child(MessageSupervisor, fn ->
                        m = @message_signatures[String.to_existing_atom(key)].parse(message)
                        Logger.debug("Message: #{inspect m}")
                        GenEvent.notify(Raven.Events, m)
                    end)
                _ -> nil

            end
        end)
    end

end
