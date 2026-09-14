defmodule Mirai.Automations.Relay.BathroomVentTimerTest do
  use ExUnit.Case, async: false

  alias Mirai.Automations.Relay.BathroomVent

  @humidity "sensor.timmerflotte_temp_hmd_sensor_humidity"
  @vent "switch.bathroom_vent_relay"

  setup do
    Process.register(self(), Mirai.HA.Connector)
    :ets.new(:mirai_state_cache, [:named_table, :set, :public])
    :ets.insert(:mirai_state_cache, {@vent, %{state: "off"}})
    {:ok, _} = Application.ensure_all_started(:phoenix_pubsub)
    start_supervised!({Phoenix.PubSub, name: Mirai.PubSub})
    %{pid: start_supervised!(BathroomVent)}
  end

  test "schedules a real 20-minute timer once and never extends it on humidity updates", %{
    pid: pid
  } do
    timer = start_run(pid)
    ref = Map.fetch!(snapshot(pid).timers, timer)
    remaining = Process.read_timer(ref)
    assert remaining > 1_190_000 and remaining <= 1_200_000

    for humidity <- ["65", "80", "58", "unavailable"] do
      deliver(pid, @humidity, humidity)
      assert snapshot(pid).timers == %{timer => ref}
      refute_command()
    end
  end

  test "timeout switches off without needing another humidity report", %{pid: pid} do
    timer = start_run(pid)
    state = expire(pid, timer)
    assert state.user_state.timed_out
    assert state.user_state.run_timer == nil
    assert state.timers == %{}
    assert_command("turn_off")
  end

  test "high humidity cannot restart a timed-out run until a reading of 55 or below", %{pid: pid} do
    timer = start_run(pid)
    expire(pid, timer)
    assert_command("turn_off")
    set_vent(pid, "off")

    for humidity <- ["80", "60", "59", "55.01", "unknown"] do
      state = deliver(pid, @humidity, humidity)
      assert state.user_state.timed_out
      refute_command()
    end

    assert deliver(pid, @humidity, "55").user_state.timed_out == false
    refute_command()
    next_timer = start_run(pid)
    assert next_timer != timer
  end

  test "manual off cancels the timer and a late timeout cannot stop a manual run", %{pid: pid} do
    timer = start_run(pid)
    ref = Map.fetch!(snapshot(pid).timers, timer)
    set_vent(pid, "off")
    assert Process.read_timer(ref) == false
    assert snapshot(pid).timers == %{}
    set_vent(pid, "on")

    send(pid, {:timer, timer})
    assert snapshot(pid).user_state.auto_started == false
    deliver(pid, @humidity, "50")
    refute_command()
  end

  test "a stale timeout from an earlier automatic run cannot stop the next run", %{pid: pid} do
    old_timer = start_run(pid)
    set_vent(pid, "off")
    new_timer = start_run(pid)
    assert old_timer != new_timer

    send(pid, {:timer, old_timer})
    state = snapshot(pid)
    assert state.user_state.run_timer == new_timer
    assert state.user_state.timed_out == false
    assert Map.has_key?(state.timers, new_timer)
    refute_command()
  end

  test "manual runs have no automatic runtime limit, including during cooldown", %{pid: pid} do
    set_vent(pid, "on")
    deliver(pid, @humidity, "65")
    deliver(pid, @humidity, "50")
    assert snapshot(pid).timers == %{}
    refute_command()

    set_vent(pid, "off")
    timer = start_run(pid)
    expire(pid, timer)
    assert_command("turn_off")
    set_vent(pid, "off")
    set_vent(pid, "on")
    deliver(pid, @humidity, "75")
    assert snapshot(pid).timers == %{}
    refute_command()
  end

  test "normal humidity shutoff cancels the runtime timer without entering cooldown", %{pid: pid} do
    timer = start_run(pid)
    ref = Map.fetch!(snapshot(pid).timers, timer)
    deliver(pid, @humidity, "55")
    assert_command("turn_off")
    state = set_vent(pid, "off")
    assert Process.read_timer(ref) == false
    assert state.user_state.timed_out == false
    assert state.timers == %{}
  end

  test "retries timed-out shutoff on a later high reading until off is confirmed", %{pid: pid} do
    timer = start_run(pid)
    expire(pid, timer)
    assert_command("turn_off")
    deliver(pid, @humidity, "70")
    assert_command("turn_off")
    set_vent(pid, "off")
    deliver(pid, @humidity, "70")
    refute_command()
  end

  defp start_run(pid) do
    state = deliver(pid, @humidity, "60")
    assert state.user_state.auto_started
    assert state.user_state.timed_out == false
    timer = state.user_state.run_timer
    assert_command("turn_on")
    set_vent(pid, "on")
    timer
  end

  defp set_vent(pid, value) do
    :ets.insert(:mirai_state_cache, {@vent, %{state: value}})
    deliver(pid, @vent, value)
  end

  defp deliver(pid, entity_id, value) do
    event = %{type: :state_change, entity_id: entity_id, new_state: %{state: value}}
    Phoenix.PubSub.broadcast(Mirai.PubSub, "ha:events", {:event, event})
    snapshot(pid)
  end

  defp snapshot(pid) do
    # Also flush timer scheduling/cancellation casts queued inside handle_event.
    :sys.get_state(pid)
    :sys.get_state(pid)
  end

  defp expire(pid, timer) do
    # Exercise the actual timer delivery path without waiting 20 minutes.
    Process.cancel_timer(Map.fetch!(snapshot(pid).timers, timer))
    send(pid, {:timer, timer})
    snapshot(pid)
  end

  defp assert_command(service) do
    assert_received {:"$gen_cast",
                     {:send, %{domain: "switch", service: ^service, target: %{entity_id: @vent}}}}

    refute_command()
  end

  defp refute_command, do: refute_received({:"$gen_cast", {:send, _}})
end
