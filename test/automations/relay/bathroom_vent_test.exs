defmodule Mirai.Automations.Relay.BathroomVentTest do
  use ExUnit.Case, async: false

  alias Mirai.Automations.Relay.BathroomVent

  @press %{
    type: :state_change,
    entity_id: "event.bathroom_vent_relay_action",
    attributes: %{"event_type" => "toggle"}
  }

  setup do
    # Capture service commands without starting Mirai or connecting to HA.
    Process.register(self(), Mirai.HA.Connector)
    :ok
  end

  test "each physical press immediately toggles the same relay exactly once" do
    state = %{preserved: true}

    for _ <- 1..2 do
      assert {:ok, ^state} = BathroomVent.handle_event(@press, state)

      assert_received {:"$gen_cast",
                       {:send,
                        %{
                          type: "call_service",
                          domain: "switch",
                          service: "toggle",
                          target: %{entity_id: "switch.bathroom_vent_relay"},
                          service_data: %{}
                        }}}

      refute_received {:"$gen_cast", _}
    end
  end

  test "relay output changes do not trigger another toggle" do
    for output <- ["on", "off"] do
      event = %{
        type: :state_change,
        entity_id: "switch.bathroom_vent_relay",
        state: output,
        attributes: %{}
      }

      assert {:ok, %{}} = BathroomVent.handle_event(event, %{})
      refute_received {:"$gen_cast", _}
    end
  end

  test "ignores unrelated events and action updates without a toggle" do
    events = [
      %{@press | entity_id: "event.bathroom_light_relay_action"},
      %{@press | type: :other},
      %{@press | attributes: %{}},
      %{@press | attributes: %{"event_type" => nil}},
      %{@press | attributes: %{"event_type" => "other"}},
      Map.delete(@press, :attributes)
    ]

    for event <- events do
      assert {:ok, %{}} = BathroomVent.handle_event(event, %{})
      refute_received {:"$gen_cast", _}
    end
  end
end
