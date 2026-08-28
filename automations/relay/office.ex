defmodule Mirai.Automations.Relay.Office do
  @moduledoc """
  Toggles the office ceiling light when its relay emits a `toggle` event.
  """

  use Mirai.Automation

  @relay_event "event.office_relay_action"
  @light "light.office_top_light_white"

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
