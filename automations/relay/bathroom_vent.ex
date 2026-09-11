defmodule Mirai.Automations.Relay.BathroomVent do
  @moduledoc """
  Controls the bathroom vent from bathroom TIMMERFLOTTE humidity updates.
  Turns on at 60% or above and off at 55% or below. Between those thresholds,
  or when the sensor reading is invalid, leaves the vent unchanged.
  """

  use Mirai.Automation

  @humidity "sensor.timmerflotte_temp_hmd_sensor_humidity"
  @vent "switch.bathroom_vent_relay"

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
      {humidity, ""} when humidity >= 60 and humidity <= 100 ->
        call_service("switch.turn_on", %{entity_id: @vent})

      {humidity, ""} when humidity >= 0 and humidity <= 55 ->
        call_service("switch.turn_off", %{entity_id: @vent})

      _ ->
        :ok
    end

    {:ok, state}
  end

  def handle_event(_event, state), do: {:ok, state}
end
