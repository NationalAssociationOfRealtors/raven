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
            description: ~x"./Description/text()"so,
            status_code: ~x"./StatusCode/text()"so,
            ext_pan_id: ~x"./ExtPanId/text()"so,
            channel: ~x"./Channel/text()"so,
            short_addr: ~x"./ShortAddr/text()"so,
            link_strength: ~x"./LinkStrength/text()"s |> transform_by(&Util.hex_to_integer/1)
        ))
    end

    def command() do
        "<Command><Name>get_connection_status</Name></Command>"
    end

end

defmodule Raven.Message.DeviceInfo do
    alias Raven.Message
    alias Raven.Util
    import SweetXml

    defstruct device_mac_id: nil,
        install_code: nil,
        link_key: nil,
        fw_version: nil,
        hw_version: nil,
        image_type: nil,
        manufacturer: nil,
        model_id: nil,
        date_code: nil

    def parse(payload) do
        Map.merge(%Message.DeviceInfo{}, payload |> xpath(
            ~x"//DeviceInfo",
            device_mac_id: ~x"./DeviceMacId/text()"s,
            install_code: ~x"./InstallCode/text()"s,
            link_key: ~x"./LinkKey/text()"s,
            fw_version: ~x"./FWVersion/text()"s,
            hw_code: ~x"./HWVersion/text()"s,
            image_type: ~x"./ImageType/text()"s,
            manufacturer: ~x"./Manufacturer/text()"s,
            model_id: ~x"./ModelId/text()"s,
            date_code: ~x"./DateCode/text()"s
        ))
    end

    def command() do
        "<Command><Name>get_device_info</Name></Command>"
    end
end

defmodule Raven.Message.ScheduleInfo do
    alias Raven.Message
    alias Raven.Util
    import SweetXml

    @events [
        "time",
        "price",
        "demand",
        "summation",
        "message"
    ]

    defstruct device_mac_id: nil,
        meter_mac_id: nil,
        event: nil,
        frequency: nil,
        enabled: nil

    def parse(payload) do
        Map.merge(%Message.ScheduleInfo{}, payload |> xpath(
            ~x"//ScheduleInfo",
            device_mac_id: ~x"./DeviceMacId/text()"s,
            meter_mac_id: ~x"./MeterMacId/text()"so,
            event: ~x"./Event/text()"s,
            frequency: ~x"./Frequency/text()"s |> transform_by(&Util.hex_to_integer/1),
            enabled: ~x"./Enabled/text()"s
        ))
    end

    def command() do
        "<Command><Name>get_schedule</Name></Command>"
    end

    def set_schedule(event, frequency, enabled \\ "Y") do
        """
        <Command>
            <Name>set_schedule</Name>
            <Event>#{event}</Event>
            <Frequency>#{Util.integer_to_hex(frequency)}</Frequency>
            <Enabled>#{enabled}</Frequency>
        </Command>
        """
    end

    def set_schedule_default(event) do
        """
        <Command>
            <Name>set_schedule_default</Name>
            <Event>#{event}</Event>
        </Command>
        """
    end
end

defmodule Raven.Message.MeterList do
    alias Raven.Message
    alias Raven.Util
    import SweetXml

    defstruct device_mac_id: nil,
        meters: []

    def parse(payload) do
        Map.merge(%Message.MeterList{}, payload |> xpath(
            ~x"//MeterList",
            device_mac_id: ~x"./DeviceMacId/text()"s,
            meters: [
                ~x"./MeterMacId"l,
                meter_mac_id:  ~x"./MeterMacId/text()"s,
            ]
        ))
    end

    def command() do
        "<Command><Name>get_meter_list</Name></Command>"
    end
end

defmodule Raven.Message.MeterInfo do
    alias Raven.Message
    alias Raven.Util
    import SweetXml

    @meter_types [
        "electric",
        "gas",
        "water",
        "other"
    ]

    defstruct device_mac_id: nil,
        meter_mac_id: nil,
        meter_type: nil,
        nick_name: nil,
        account: nil,
        auth: nil,
        host: nil,
        enabled: nil

    def parse(payload) do
        Map.merge(%Message.MeterInfo{}, payload |> xpath(
            ~x"//MeterInfo",
            device_mac_id: ~x"./DeviceMacId/text()"s,
            meter_mac_id: ~x"./MeterMacId/text()"s,
            meter_type: ~x"./MeterType/text()"s,
            nick_name: ~x"./NickName/text()"s,
            account: ~x"./Account/text()"so,
            auth: ~x"./Auth/text()"so,
            host: ~x"./Host/text()"so,
            enabled: ~x"./Enabled/text()"so
        ))
    end

    def command() do
        "<Command><Name>get_meter_info</Name></Command>"
    end

    def set_meter_info(nick_name, account, auth, host, enabled) do
        """
        <Command>
            <Name>set_meter_info</Name>
            <NickName>#{nick_name}</NickName>
            <Account>#{account}</Account>
            <Auth>#{auth}</Auth>
            <Host>#{host}</Host>
            <Enabled>#{nick_name}</Enabled>
        """
    end
end

defmodule Raven.Message.NetworkInfo do
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
        coord_mac_id: nil,
        status: nil,
        description: "",
        status_code: 0,
        ext_pan_id: nil,
        channel: nil,
        short_addr: nil,
        link_strength: nil

    def parse(payload) do
        Map.merge(%Message.NetworkInfo{}, payload |> xpath(
            ~x"//NetworkInfo",
            device_mac_id: ~x"./DeviceMacId/text()"s,
            coord_mac_id: ~x"./CoordMacId/text()"s,
            status: ~x"./Status/text()"s,
            description: ~x"./Description/text()"s,
            status_code: ~x"./StatusCode/text()"s,
            ext_pan_id: ~x"./ExtPanId/text()"s,
            channel: ~x"./Channel/text()"s,
            short_addr: ~x"./ShortAddr/text()"s,
            link_strength: ~x"./LinkStrength/text()"s |> transform_by(&Util.hex_to_integer/1)
        ))
    end

    def command() do
        "<Command><Name>get_network_info</Name></Command>"
    end

end

defmodule Raven.Message.TimeCluster do
    alias Raven.Message
    alias Raven.Util
    import SweetXml

    defstruct device_mac_id: nil,
        meter_mac_id: nil,
        utc_time: nil,
        local_time: 0

    def parse(payload) do
        message = Map.merge(%Message.TimeCluster{}, payload |> xpath(
            ~x"//TimeCluster",
            device_mac_id: ~x"./DeviceMacId/text()"s,
            meter_mac_id: ~x"./MeterMacId/text()"s,
            utc_time: ~x"./UTCTime/text()"s |> transform_by(&Util.hex_to_integer/1),
            local_time: ~x"./LocalTime/text()"s |> transform_by(&Util.hex_to_integer/1),
        ))
    end

    def command() do
        "<Command><Name>get_time</Name></Command>"
    end

end

defmodule Raven.Message.MessageCluster do
    alias Raven.Message
    alias Raven.Util
    import SweetXml

    defstruct device_mac_id: nil,
        meter_mac_id: nil,
        time_stamp: nil,
        id: nil,
        text: nil,
        confirmation_required: nil,
        confirmed: nil,
        queue: nil

    def parse(payload) do
        message = Map.merge(%Message.MessageCluster{}, payload |> xpath(
            ~x"//MessageCluster",
            device_mac_id: ~x"./DeviceMacId/text()"s,
            meter_mac_id: ~x"./MeterMacId/text()"s,
            time_stamp: ~x"./TimeStamp/text()"s |> transform_by(&Util.hex_to_integer/1),
            id: ~x"./Id/text()"s |> transform_by(&Util.hex_to_integer/1),
            text: ~x"./text/text()"s,
            confirmation_required: ~x"./ConfirmationRequired/text()"s,
            confirmed: ~x"./Confirmed/text()"s,
            queue: ~x"./Queue/text()"s
        ))
    end

    def command() do
        "<Command><Name>get_message</Name></Command>"
    end

    def confirm(id) do
        """
        <Command>
            <Name>confirm_message</Name>
            <Id>#{id}</Id>
        </Command>
        """
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

defmodule Raven.Message.CurrentSummationDelivered do
    alias Raven.Message
    alias Raven.Util
    import SweetXml

    defstruct device_mac_id: nil,
        meter_mac_id: nil,
        time_stamp: nil,
        summation_delivered: 0,
        summation_received: 0,
        multiplier: 1,
        divisor: 1000
        kw_delivered: 0,
        kw_received: 0

    def parse(payload) do
        message = Map.merge(%Message.CurrentSummationDelivered{}, payload |> xpath(
            ~x"//CurrentSummationDelivered",
            device_mac_id: ~x"./DeviceMacId/text()"s,
            meter_mac_id: ~x"./MeterMacId/text()"s,
            time_stamp: ~x"./TimeStamp/text()"s |> transform_by(&Util.hex_to_integer/1),
            summation_delivered: ~x"./SummationDelivered/text()"s |> transform_by(&Util.hex_to_integer/1),
            summation_received: ~x"./SummationReceived/text()"s |> transform_by(&Util.hex_to_integer/1),
            multiplier: ~x"./Multiplier/text()"s |> transform_by(&Util.hex_to_integer/1),
            divisor: ~x"./Divisor/text()"s |> transform_by(&Util.hex_to_integer/1)
        ))
        %Message.InstantaneousDemand{message |
            :kw_delivered => (message.summation_delivered*message.multiplier)/message.divisor,
            :kw_received => (message.summation_received*message.multiplier)/message.divisor,
        }
    end

    def command() do
        "<Command><Name>get_current_summation_delivered</Name></Command>"
    end

end

defmodule Raven.Message.Initialize do

    def command() do
        "<Command><Name>initialize</Name></Command>"
    end

end

defmodule Raven.Message.Restart do

    def command() do
        "<Command><Name>restart</Name></Command>"
    end

end

defmodule Raven.Message.FactoryReset do

    def command() do
        "<Command><Name>factory_reset</Name></Command>"
    end

end
