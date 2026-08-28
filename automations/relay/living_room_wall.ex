defmodule Mirai.Automations.Relay.LivingRoomWall do
  @moduledoc """
  Toggles the living-room wall lights when the side relay changes state.
  """

  use Mirai.Automation

  @relay_event "event.living_room_side_relay_action"

  @impl Mirai.Automation
  def handle_event(
        %{type: :state_change, entity_id: @relay_event},
        state
      ) do
    call_service("light.toggle", %{
      entity_id: "light.stockholm",
      color_temp_kelvin: 2000,
      brightness_pct: 10
    })

    call_service("light.toggle", %{
      entity_id: "light.living_room_side",
      color_temp_kelvin: 2000,
      brightness_pct: 40
    })

    {:ok, state}
  end

  def handle_event(_event, state), do: {:ok, state}
end
