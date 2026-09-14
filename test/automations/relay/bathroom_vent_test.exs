defmodule Mirai.Automations.Relay.BathroomVentTest do
  use ExUnit.Case, async: false

  alias Mirai.Automations.Relay.BathroomVent
  alias Mirai.HA.Normalizer

  @humidity "sensor.timmerflotte_temp_hmd_sensor_humidity"
  @vent "switch.bathroom_vent_relay"
  @manual %{auto_started: false, run_timer: nil, timed_out: false}
  @automatic %{auto_started: true, run_timer: nil, timed_out: false}

  setup do
    # Capture commands and provide the real StateCache read interface without HA.
    Process.register(self(), Mirai.HA.Connector)
    :ets.new(:mirai_state_cache, [:named_table, :set, :public])
    cache_vent("off")
    :ok
  end

  test "turns an off vent on at or above 60 percent and claims ownership" do
    for humidity <- ["60", "60.0", "60.01", "75.5", "100"] do
      assert {:ok, %{auto_started: true, run_timer: timer, timed_out: false}} =
               BathroomVent.handle_event(humidity_event(humidity), @manual)

      assert_received {:"$gen_cast", {:schedule_timer, ^timer, 1_200_000}}
      assert_command("turn_on")
    end
  end

  test "does not turn a manually started vent off at low humidity" do
    cache_vent("on")

    for humidity <- ["55", "50", "40", "0"] do
      assert {:ok, @manual} = BathroomVent.handle_event(humidity_event(humidity), @manual)
      refute_received {:"$gen_cast", _}
    end
  end

  test "does not adopt a manually running vent when humidity rises above 60" do
    cache_vent("on")

    for humidity <- ["60", "75", "59", "55", "50"] do
      assert {:ok, @manual} = BathroomVent.handle_event(humidity_event(humidity), @manual)
      refute_received {:"$gen_cast", _}
    end
  end

  test "turns only an automatically started vent off at or below 55 percent" do
    cache_vent("on")

    for humidity <- ["55", "55.0", "54.99", "40.5", "0"] do
      assert {:ok, @automatic} = BathroomVent.handle_event(humidity_event(humidity), @automatic)
      assert_command("turn_off")
    end

    # Keep ownership until the output confirms off, allowing retry on the next report.
    assert {:ok, @manual} = BathroomVent.handle_event(vent_event("off"), @automatic)
  end

  test "manual off then on clears ownership and protects the new manual session" do
    assert {:ok, state} = BathroomVent.handle_event(vent_event("off"), @automatic)
    assert state == @manual
    cache_vent("on")
    assert {:ok, ^state} = BathroomVent.handle_event(vent_event("on"), state)
    assert {:ok, ^state} = BathroomVent.handle_event(humidity_event("50"), state)
    refute_received {:"$gen_cast", _}
  end

  test "does not issue duplicate on commands while it owns the vent" do
    for output <- ["off", "on"] do
      cache_vent(output)
      assert {:ok, @automatic} = BathroomVent.handle_event(humidity_event("65"), @automatic)
      refute_received {:"$gen_cast", _}
    end
  end

  test "does not start a vent whose output state is unknown or unavailable" do
    for output <- ["unknown", "unavailable"] do
      cache_vent(output)
      assert {:ok, @manual} = BathroomVent.handle_event(humidity_event("65"), @manual)
      refute_received {:"$gen_cast", _}
    end

    :ets.delete(:mirai_state_cache, @vent)
    assert {:ok, @manual} = BathroomVent.handle_event(humidity_event("65"), @manual)
    refute_received {:"$gen_cast", _}
  end

  test "releases ownership when the vent turns off or its state becomes uncertain" do
    for output <- ["off", "unknown", "unavailable", nil] do
      assert {:ok, @manual} = BathroomVent.handle_event(vent_event(output), @automatic)
      refute_received {:"$gen_cast", _}
    end

    event = %{vent_event("on") | new_state: nil}
    assert {:ok, @manual} = BathroomVent.handle_event(event, @automatic)
  end

  test "releases stale ownership without sending off when the cache is not on" do
    for output <- ["off", "unknown", "unavailable"] do
      cache_vent(output)
      assert {:ok, @manual} = BathroomVent.handle_event(humidity_event("50"), @automatic)
      refute_received {:"$gen_cast", _}
    end
  end

  test "leaves the vent and ownership unchanged strictly between thresholds" do
    for owner <- [false, true], humidity <- ["55.01", "57.5", "59.99"] do
      state = %{auto_started: owner, preserved: true}
      assert {:ok, ^state} = BathroomVent.handle_event(humidity_event(humidity), state)
      refute_received {:"$gen_cast", _}
    end
  end

  test "ignores missing, unavailable, malformed and out-of-range humidity" do
    for state <- [@manual, @automatic],
        humidity <- [nil, "unknown", "unavailable", "", "60%", "60garbage", "NaN", "-1", "101"] do
      assert {:ok, ^state} = BathroomVent.handle_event(humidity_event(humidity), state)
      refute_received {:"$gen_cast", _}
    end

    event = humidity_event("60")

    for event <- [%{event | new_state: nil}, Map.delete(event, :new_state)] do
      assert {:ok, @automatic} = BathroomVent.handle_event(event, @automatic)
      refute_received {:"$gen_cast", _}
    end
  end

  test "ignores relay press actions, on confirmations and other sensors" do
    events = [
      %{
        type: :state_change,
        entity_id: "event.bathroom_vent_relay_action",
        attributes: %{"event_type" => "toggle"}
      },
      vent_event("on"),
      %{humidity_event("60") | entity_id: "sensor.other_humidity"},
      %{humidity_event("60") | type: :other}
    ]

    for event <- events do
      assert {:ok, @automatic} = BathroomVent.handle_event(event, @automatic)
      refute_received {:"$gen_cast", _}
    end
  end

  test "delivers an automatic cycle and a manual session through the running automation" do
    {:ok, _} = Application.ensure_all_started(:phoenix_pubsub)
    start_supervised!({Phoenix.PubSub, name: Mirai.PubSub})
    pid = start_supervised!(BathroomVent)

    automatic = deliver(pid, humidity_event("60"))
    assert automatic.auto_started
    assert automatic.run_timer
    assert_command("turn_on")
    cache_vent("on")
    assert deliver(pid, vent_event("on")) == automatic

    for humidity <- ["65", "59", "55.01"] do
      assert deliver(pid, humidity_event(humidity)) == automatic
      refute_received {:"$gen_cast", _}
    end

    assert deliver(pid, humidity_event("55")) == automatic
    assert_command("turn_off")
    cache_vent("off")
    assert deliver(pid, vent_event("off")) == @manual

    cache_vent("on")
    assert deliver(pid, vent_event("on")) == @manual
    assert deliver(pid, humidity_event("50")) == @manual
    refute_received {:"$gen_cast", _}
  end

  test "after a restart an already running vent is conservatively treated as manual" do
    {:ok, _} = Application.ensure_all_started(:phoenix_pubsub)
    start_supervised!({Phoenix.PubSub, name: Mirai.PubSub})
    cache_vent("on")
    pid = start_supervised!(BathroomVent)

    assert deliver(pid, humidity_event("65")) == @manual
    assert deliver(pid, humidity_event("50")) == @manual
    refute_received {:"$gen_cast", _}
  end

  defp cache_vent(value), do: :ets.insert(:mirai_state_cache, {@vent, %{state: value}})

  defp humidity_event(value), do: state_event(@humidity, value)
  defp vent_event(value), do: state_event(@vent, value)

  defp state_event(entity_id, value) do
    Normalizer.normalize(%{
      "type" => "event",
      "event" => %{
        "event_type" => "state_changed",
        "data" => %{
          "entity_id" => entity_id,
          "old_state" => nil,
          "new_state" => %{"state" => value, "attributes" => %{}}
        }
      }
    })
  end

  defp deliver(pid, event) do
    Phoenix.PubSub.broadcast(Mirai.PubSub, "ha:events", {:event, event})
    # Flush local delivery before checking for absent service commands.
    :sys.get_state(pid).user_state
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
