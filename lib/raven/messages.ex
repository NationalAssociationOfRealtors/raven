defmodule Raven.Message.ConnectionStatus do
    alias Raven.Message
    alias Raven.Util
    import SweetXml

    @status [
        "Initializing",
        "Network Discovery",
        "Joining",
        "Join: Fail",
        "Join: Success",
        "Authenticating",
        "Authenticating: Success",
        "Authenticating: Fail",
        "Connected",
        "Disconnected",
        "Rejoining"
    ]

    defstruct device_mac_id: nil,
        meter_mac_id: nil,
        status: nil,
        description: "",
        status_code: 0,
        ext_pan_id: nil,
        channel: nil,
        short_addr: nil,
        link_strength: nil

    def parse(payload) do
        Map.merge(%Message.ConnectionStatus{}, payload |> xpath(
            ~x"//ConnectionStatus",
            device_mac_id: ~x"./DeviceMacId/text()"s,
            meter_mac_id: ~x"./MeterMacId/text()"s,
            status: ~x"./Status/text()"s,
            description: ~x"./Description/text()"s,
            status_code: ~x"./StatusCode/text()"s,
            ext_pan_id: ~x"./ExtPanId/text()"s,
            channel: ~x"./Channel/text()"s,
            short_addr: ~x"./ShortAddr/text()"s,
            link_strength: ~x"./LinkStrength/text()"s
        ))
    end

    def command() do
        "<Command><Name>get_connection_status</Name></Command>"
    end

end

defmodule Raven.Message.InstantaneousDemand do
    alias Raven.Message
    alias Raven.Util
    import SweetXml

    defstruct device_mac_id: nil,
        meter_mac_id: nil,
        time_stamp: nil,
        demand: 0,
        multiplier: 1,
        divisor: 1000,
        kw: 0

    def parse(payload) do
        message = Map.merge(%Message.InstantaneousDemand{}, payload |> xpath(
            ~x"//InstantaneousDemand",
            device_mac_id: ~x"./DeviceMacId/text()"s,
            meter_mac_id: ~x"./MeterMacId/text()"s,
            time_stamp: ~x"./TimeStamp/text()"s |> transform_by(&Util.hex_to_integer/1),
            demand: ~x"./Demand/text()"s |> transform_by(&Util.hex_to_integer/1),
            multiplier: ~x"./Multiplier/text()"s |> transform_by(&Util.hex_to_integer/1),
            divisor: ~x"./Divisor/text()"s |> transform_by(&Util.hex_to_integer/1)
        ))
        %Message.InstantaneousDemand{message |
            :kw => (message.demand*message.multiplier)/message.divisor
        }
    end

    def command() do
        "<Command><Name>get_instantaneous_demand</Name></Command>"
    end

end

defmodule Raven.Message.PriceCluster do
    alias Raven.Message
    alias Raven.Util
    import SweetXml

    defstruct device_mac_id: nil,
        meter_mac_id: nil,
        time_stamp: nil,
        price: 0,
        currency: 0,
        tier: 0,
        tier_label: nil,
        rate_label: nil,
        trailing_digits: 2

    def parse(payload) do
        message = Map.merge(%Message.PriceCluster{}, payload |> xpath(
            ~x"//PriceCluster",
            device_mac_id: ~x"./DeviceMacId/text()"s,
            meter_mac_id: ~x"./MeterMacId/text()"s,
            time_stamp: ~x"./TimeStamp/text()"s |> transform_by(&Util.hex_to_integer/1),
            price: ~x"./Price/text()"s |> transform_by(&Util.hex_to_integer/1),
            trailing_digits: ~x"./TrailingDigits/text()"s |> transform_by(&Util.hex_to_integer/1),
            currency: ~x"./Currency/text()"s |> transform_by(&Util.hex_to_integer/1),
            tier: ~x"./Tier/text()"s |> transform_by(&Util.hex_to_integer/1),
            tier_label: ~x"./Tier/text()"os,
            rate_label: ~x"./RateLabel/text()"os
        ))
        divisor = String.pad_trailing("1", message.trailing_digits+1, "0") |> String.to_integer
        %Message.PriceCluster{message |
            :price => message.price/divisor
        }
    end

    def command() do
        "<Command><Name>get_current_price</Name></Command>"
    end

end
