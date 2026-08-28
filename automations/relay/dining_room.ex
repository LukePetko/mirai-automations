defmodule Mirai.Automations.Relay.DiningRoom do
  @moduledoc """
  Toggles the dining-room lights when their relay changes state.
  """

  use Mirai.Automation

  @relay_event "event.dining_room_relay_action"
  @light "light.dining_room_lights"

  @impl Mirai.Automation
  def handle_event(
        %{type: :state_change, entity_id: @relay_event},
        state
      ) do
    call_service("light.toggle", %{entity_id: @light})
    {:ok, state}
  end

  def handle_event(_event, state), do: {:ok, state}
end
