defmodule RavenTest do
    use ExUnit.Case
    doctest Raven

    test "the truth" do
        assert 1 + 1 == 2
    end

    test "event handler" do
        Raven.EventManager.add_handler(Raven.Handler)
        assert_receive(%Raven.Meter.State{}, 450000)
        assert_receive(%Raven.Client.State{}, 450000)
    end

end
