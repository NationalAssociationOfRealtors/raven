defmodule Raven.Mixfile do
  use Mix.Project

  def project do
    [app: :raven,
     version: "0.1.0",
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
      mod: {Raven, []}
    ]
  end

  def description do
      """
      A Client for the Rainforest Automation Raven USB Stick
      """
  end

  def package do
    [
      name: :raven,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Christopher Steven Coté"],
      licenses: ["MIT License"],
      links: %{"GitHub" => "https://github.com/NationalAssociationOfRealtors/raven",
          "Docs" => "https://github.com/NationalAssociationOfRealtors/raven"}
    ]
  end

  defp deps do
    [
        {:nerves_uart, "~> 0.1.0"},
        {:sweet_xml, "~> 0.6.1"},
    ]
  end
end
