defmodule Raven.Util do

    def hex_to_integer(hex) do
        <<"0x", rest::binary >> = hex
        Integer.parse(rest, 16) |> elem(0)
    end

end
