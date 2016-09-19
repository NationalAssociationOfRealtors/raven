defmodule Raven do
  use Application
  require Logger
  alias Nerves.UART, as: Serial

  def start(_type, _args) do
    get_tty
    {:ok, pid} = Raven.Supervisor.start_link
  end

  def get_tty do
    Serial.enumerate |> Enum.each(fn({tty, device}) ->
      case device.product_id do
        35368 ->
          Logger.info("Setting Raven TTY: #{inspect tty}")
          Application.put_env(:raven_smcd, :tty, "/dev/#{tty}", persistent: true)
        _ -> nil
      end
    end)
  end

end
