defmodule Mirai.Automations.Button.NikiTest do
  use ExUnit.Case, async: false

  alias Mirai.Automations.Button.Niki
  alias Mirai.HA.Normalizer

  @button "event.niki_button_action"
  @light "light.office_top_light_white"

  setup do
    # Intercept commands without starting Mirai or operating the real light.
    Process.register(self(), Mirai.HA.Connector)
    :ok
  end

  test "toggles the white light once for each consecutive single press" do
    state = %{preserved: true}

    for timestamp <- ["2026-09-22T06:44:29.440+00:00", "2026-09-22T06:44:30.500+00:00"] do
      assert {:ok, ^state} = Niki.handle_event(button_event("single", timestamp), state)
      assert_toggle()
    end
  end

  test "ignores other button actions and unavailable action values" do
    for action <- ["double", "triple", "quadruple", "hold", "release", nil, "unknown"] do
      assert {:ok, %{}} = Niki.handle_event(button_event(action), %{})
      refute_received {:"$gen_cast", _}
    end
  end

  test "ignores unrelated entities, event types and missing attributes" do
    event = button_event("single")

    for ignored <- [
          %{event | entity_id: "event.other_button_action"},
          %{event | entity_id: @light},
          %{event | type: :other},
          %{event | attributes: %{}},
          Map.delete(event, :attributes)
        ] do
      assert {:ok, %{}} = Niki.handle_event(ignored, %{})
      refute_received {:"$gen_cast", _}
    end
  end

  test "handles the normalized HA event through the running automation" do
    {:ok, _} = Application.ensure_all_started(:phoenix_pubsub)
    start_supervised!({Phoenix.PubSub, name: Mirai.PubSub})
    pid = start_supervised!(Niki)

    for timestamp <- ["2026-09-22T06:44:29.440+00:00", "2026-09-22T06:44:30.500+00:00"] do
      Phoenix.PubSub.broadcast(
        Mirai.PubSub,
        "ha:events",
        {:event, button_event("single", timestamp)}
      )

      # Flush delivery before checking that exactly one command was emitted.
      :sys.get_state(pid)
      assert_toggle()
    end
  end

  defp button_event(action, timestamp \\ "2026-09-22T06:44:29.440+00:00") do
    Normalizer.normalize(%{
      "type" => "event",
      "event" => %{
        "event_type" => "state_changed",
        "data" => %{
          "entity_id" => @button,
          "old_state" => %{
            "state" => "2026-09-22T06:44:28.865+00:00",
            "attributes" => %{"event_type" => "single"}
          },
          "new_state" => %{
            "state" => timestamp,
            "attributes" => %{"event_type" => action}
          }
        }
      }
    })
  end

  defp assert_toggle do
    assert_received {:"$gen_cast",
                     {:send,
                      %{
                        type: "call_service",
                        domain: "light",
                        service: "toggle",
                        target: %{entity_id: @light},
                        service_data: %{}
                      }}}

    refute_received {:"$gen_cast", _}
  end
end
