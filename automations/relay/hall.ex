defmodule Mirai.Automations.Relay.Hall do
  @moduledoc """
  Toggles the hall light when its relay emits a `toggle` event.
  """

  use Mirai.Automation

  @relay_event "event.hall_relay_action"
  @light "light.hall_light"

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
