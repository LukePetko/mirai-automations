defmodule Mirai.Automations.Relay.BathroomVentTest do
  use ExUnit.Case, async: false

  alias Mirai.Automations.Relay.BathroomVent
  alias Mirai.HA.Normalizer

  @humidity "sensor.timmerflotte_temp_hmd_sensor_humidity"
  @vent "switch.bathroom_vent_relay"

  setup do
    # Capture service commands without starting Mirai or connecting to HA.
    Process.register(self(), Mirai.HA.Connector)
    :ok
  end

  test "turns on at or above 60 percent humidity" do
    for humidity <- ["60", "60.0", "60.01", "75.5", "100"] do
      assert {:ok, %{}} = BathroomVent.handle_event(humidity_event(humidity), %{})
      assert_command("turn_on")
    end
  end

  test "turns off at or below 55 percent humidity" do
    for humidity <- ["55", "55.0", "54.99", "40.5", "0"] do
      assert {:ok, %{}} = BathroomVent.handle_event(humidity_event(humidity), %{})
      assert_command("turn_off")
    end
  end

  test "leaves the vent unchanged strictly between the thresholds" do
    state = %{preserved: true}

    for humidity <- ["55.01", "57.5", "59.99"] do
      assert {:ok, ^state} = BathroomVent.handle_event(humidity_event(humidity), state)
      refute_received {:"$gen_cast", _}
    end
  end

  test "ignores missing, unavailable, malformed and out-of-range humidity" do
    for humidity <- [nil, "unknown", "unavailable", "", "60%", "60garbage", "NaN", "-1", "101"] do
      assert {:ok, %{}} = BathroomVent.handle_event(humidity_event(humidity), %{})
      refute_received {:"$gen_cast", _}
    end

    event = humidity_event("60")

    for event <- [%{event | new_state: nil}, Map.delete(event, :new_state)] do
      assert {:ok, %{}} = BathroomVent.handle_event(event, %{})
      refute_received {:"$gen_cast", _}
    end
  end

  test "ignores relay presses, vent output changes and other sensors" do
    events = [
      %{
        type: :state_change,
        entity_id: "event.bathroom_vent_relay_action",
        attributes: %{"event_type" => "toggle"}
      },
      %{humidity_event("60") | entity_id: @vent},
      %{humidity_event("60") | entity_id: "sensor.other_humidity"},
      %{humidity_event("60") | type: :other}
    ]

    for event <- events do
      assert {:ok, %{}} = BathroomVent.handle_event(event, %{})
      refute_received {:"$gen_cast", _}
    end
  end

  test "normalizes and delivers a humidity cycle through the running automation" do
    {:ok, _} = Application.ensure_all_started(:phoenix_pubsub)
    start_supervised!({Phoenix.PubSub, name: Mirai.PubSub})
    pid = start_supervised!(BathroomVent)

    for {humidity, command} <- [
          {"52.85", "turn_off"},
          {"58", nil},
          {"60", "turn_on"},
          {"65", "turn_on"},
          {"59", nil},
          {"55.01", nil},
          {"55", "turn_off"}
        ] do
      Phoenix.PubSub.broadcast(Mirai.PubSub, "ha:events", {:event, humidity_event(humidity)})
      # Synchronize with the GenServer so absence-of-command assertions are reliable.
      :sys.get_state(pid)

      if command, do: assert_command(command), else: refute_received({:"$gen_cast", _})
    end
  end

  defp humidity_event(value) do
    Normalizer.normalize(%{
      "type" => "event",
      "event" => %{
        "event_type" => "state_changed",
        "data" => %{
          "entity_id" => @humidity,
          "old_state" => nil,
          "new_state" => %{
            "state" => value,
            "attributes" => %{"device_class" => "humidity", "unit_of_measurement" => "%"}
          }
        }
      }
    })
  end

  defp assert_command(service) do
    assert_received {:"$gen_cast",
                     {:send,
                      %{
                        type: "call_service",
                        domain: "switch",
                        service: ^service,
                        target: %{entity_id: @vent},
                        service_data: %{}
                      }}}

    refute_received {:"$gen_cast", _}
  end
end
