defmodule Raven.Mixfile do
  use Mix.Project
  alias Raven.Message

  def project do
    [app: :raven_smcd,
     version: "0.2.1",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:logger, :nerves_uart, :sweet_xml, :xmerl],
      mod: {Raven, []},
      env: [speed: 115200,
        tty: "/dev/ttyUSB9879879799",
        message_signatures: %{
          "ConnectionStatus": Message.ConnectionStatus,
          "DeviceInfo": Message.DeviceInfo,
          "ScheduleInfo": Message.ScheduleInfo,
          "MeterList": Message.MeterList,
          "MeterInfo": Message.MeterInfo,
          "NetworkInfo": Message.NetworkInfo,
          "TimeCluster": Message.TimeCluster,
          "MessageCluster": Message.MessageCluster,
          "PriceCluster": Message.PriceCluster,
          "InstantaneousDemand": Message.InstantaneousDemand,
          "CurrentSummationDelivered": Message.CurrentSummationDelivered
      }]
    ]
  end

  def description do
      """
      A Client for the Rainforest Automation Raven USB SMCD (Smart Meter Connected Device)
      """
  end

  def package do
    [
      name: :raven_smcd,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Christopher Steven Coté"],
      licenses: ["Apache License 2.0"],
      links: %{"GitHub" => "https://github.com/NationalAssociationOfRealtors/raven",
          "Docs" => "https://github.com/NationalAssociationOfRealtors/raven"}
    ]
  end

  defp deps do
    [
        {:nerves_uart, "~> 0.1.1"},
        {:sweet_xml, "~> 0.6.1"},
        {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
