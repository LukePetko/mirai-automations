defmodule Mirai.Automations.Relay.LivingRoomMain do
  @moduledoc """
  Toggles the main living-room light when its relay emits a `toggle` event.
  """

  use Mirai.Automation

  @relay_event "event.living_room_main_relay_action"
  @light "light.living_room_main"

  @impl Mirai.Automation
  def handle_event(
        %{
          type: :state_change,
          entity_id: @relay_event,
          attributes: %{"event_type" => "toggle"}
        },
        state
      ) do
    call_service("light.toggle", %{entity_id: @light})
    {:ok, state}
  end

  def handle_event(_event, state), do: {:ok, state}
end
