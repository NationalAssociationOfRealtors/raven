# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

alias Raven.Message

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

keys = [
    "</ConnectionStatus>",
    "</DeviceInfo>",
    "</ScheduleInfo>",
    "</MeterList>",
    "</MeterInfo>",
    "</NetworkInfo>",
    "</TimeCluster>",
    "</MessageCluster>",
    "</PriceCluster>",
    "</InstantaneousDemand>",
    "</CurrentSummationDelivered>"
]

config :raven,
    speed: 115200,
    tty: "/dev/ttyUSB0",
    message_signatures: %{
        "</ConnectionStatus>": Message.ConnectionStatus,
        "</DeviceInfo>": Message.DeviceInfo,
        "</ScheduleInfo>": Message.ScheduleInfo,
        "</MeterList>": Message.MeterList,
        "</MeterInfo>": Message.MeterInfo,
        "</NetworkInfo>": Message.NetworkInfo,
        "</TimeCluster>": Message.TimeCluster,
        "</MessageCluster>": Message.MessageCluster,
        "</PriceCluster>": Message.PriceCluster,
        "</InstantaneousDemand>": Message.InstantaneousDemand,
        "</CurrentSummationDelivered>": Message.CurrentSummationDelivered
    },
    message_keys: keys

# You can configure for your application as:
#
#     config :raven, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:raven, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"
