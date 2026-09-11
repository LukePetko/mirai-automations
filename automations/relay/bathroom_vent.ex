defmodule Mirai.Automations.Relay.BathroomVent do
  @moduledoc """
  Controls the bathroom vent from bathroom TIMMERFLOTTE humidity updates.
  Starts an off vent at 60% or above. At 55% or below, stops it only if this
  automation started it. A manually running vent is never adopted.

  Off or unavailable output states release automatic ownership. Ownership is
  intentionally not restored after a restart, protecting existing manual runs.
  Between thresholds or with invalid humidity, leaves the vent unchanged.
  """

  use Mirai.Automation

  @humidity "sensor.timmerflotte_temp_hmd_sensor_humidity"
  @vent "switch.bathroom_vent_relay"

  @impl Mirai.Automation
  def initial_state, do: %{auto_started: false}

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
    do: {:ok, %{state | auto_started: false}}

  def handle_event(_event, state), do: {:ok, state}

  defp control_vent(humidity, %{auto_started: false} = state) when humidity >= 60 do
    case get_state(@vent) do
      {:ok, %{state: "off"}} ->
        call_service("switch.turn_on", %{entity_id: @vent})
        {:ok, %{state | auto_started: true}}

      _ ->
        {:ok, state}
    end
  end

  defp control_vent(humidity, %{auto_started: true} = state) when humidity <= 55 do
    case get_state(@vent) do
      {:ok, %{state: "on"}} ->
        call_service("switch.turn_off", %{entity_id: @vent})
        # Retain ownership until off is observed so a later report can retry.
        {:ok, state}

      _ ->
        {:ok, %{state | auto_started: false}}
    end
  end

  defp control_vent(_humidity, state), do: {:ok, state}
end
