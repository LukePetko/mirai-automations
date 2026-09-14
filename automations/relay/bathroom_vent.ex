defmodule Mirai.Automations.Relay.BathroomVent do
  @moduledoc """
  Controls the bathroom vent from bathroom TIMMERFLOTTE humidity updates.
  Starts an off vent at 60% or above. At 55% or below, stops it only if this
  automation started it. Automatic runs also stop after 20 minutes, regardless
  of humidity, then wait for a reading of 55% or below before allowing a new run.
  Manual runs are never adopted or timed out.

  Off or unavailable output states release ownership and cancel the timer.
  Ownership and cooldown are not restored after a restart, protecting existing
  manual runs. Invalid humidity never triggers a new action or resets the timer.
  """

  use Mirai.Automation

  @humidity "sensor.timmerflotte_temp_hmd_sensor_humidity"
  @vent "switch.bathroom_vent_relay"
  @max_runtime :timer.minutes(20)

  @impl Mirai.Automation
  def initial_state, do: %{auto_started: false, run_timer: nil, timed_out: false}

  @impl Mirai.Automation
  def handle_event(
        %{
          type: :state_change,
          entity_id: @humidity,
          new_state: %{state: reading}
        },
        state
      )
      when is_binary(reading) do
    case Float.parse(reading) do
      {humidity, ""} when humidity >= 0 and humidity <= 100 ->
        control_vent(humidity, state)

      _ ->
        {:ok, state}
    end
  end

  def handle_event(
        %{type: :state_change, entity_id: @vent, new_state: %{state: "on"}},
        state
      ),
      do: {:ok, state}

  def handle_event(%{type: :state_change, entity_id: @vent}, state),
    do: release_vent(state)

  def handle_event(_event, state), do: {:ok, state}

  @impl Mirai.Automation
  def handle_message(
        {:max_runtime, _run_id} = timer,
        %{auto_started: true, run_timer: timer} = state
      ) do
    stop_vent(%{state | run_timer: nil, timed_out: true})
  end

  def handle_message(_message, state), do: {:ok, state}

  defp control_vent(humidity, state) when humidity <= 55 do
    state = %{state | timed_out: false}
    if state.auto_started, do: stop_vent(state), else: {:ok, state}
  end

  defp control_vent(_humidity, %{auto_started: true, timed_out: true} = state),
    do: stop_vent(state)

  defp control_vent(humidity, %{auto_started: false, timed_out: false} = state)
       when humidity >= 60 do
    case get_state(@vent) do
      {:ok, %{state: "off"}} ->
        # A unique key prevents an already-queued old timeout stopping a new run.
        timer = {:max_runtime, make_ref()}
        call_service("switch.turn_on", %{entity_id: @vent})
        schedule_timer(timer, @max_runtime)
        {:ok, %{state | auto_started: true, run_timer: timer}}

      _ ->
        {:ok, state}
    end
  end

  defp control_vent(_humidity, state), do: {:ok, state}

  defp stop_vent(state) do
    case get_state(@vent) do
      {:ok, %{state: "on"}} ->
        call_service("switch.turn_off", %{entity_id: @vent})
        # Retain ownership until off is observed so a later report can retry.
        {:ok, state}

      _ ->
        release_vent(state)
    end
  end

  defp release_vent(state) do
    if state.run_timer, do: cancel_timer(state.run_timer)
    {:ok, %{state | auto_started: false, run_timer: nil}}
  end
end
