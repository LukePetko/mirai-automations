defmodule Mirai.Automations.MotionSensorTest do
  @moduledoc """
  """
  use Mirai.Automation
  alias Mirai.Automations.SharedActions

  @kitchen_lights ["light.kitchen_1", "light.kitchen_2"]

  def handle_event(
        %{
          entity_id: "binary_sensor.motion_sensor_test_presence",
          new_state: %{state: "on"}
        },
        state
      ) do
      call_service("light.turn_on", %{entity_id: @kitchen_lights, brightness_pct: 100})
    {:ok, state}
  end

  def handle_event(
        %{entity_id: "binary_sensor.motion_sensor_test_presence", new_state: %{state: "off"}},
        state
      ) do
      call_service("light.turn_off", %{area_id: "kitchen"})
    {:ok, state}
  end

  def handle_event(_event, state), do: {:ok, state}
end
