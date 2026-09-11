defmodule Mirai.Automations.Relay.BathroomVent do
  @moduledoc """
  Immediately toggles the bathroom vent relay back after a physical press.
  Only action events are handled, not changes to the relay's output state.
  """

  use Mirai.Automation

  @relay_event "event.bathroom_vent_relay_action"
  @relay "switch.bathroom_vent_relay"

  @impl Mirai.Automation
  def handle_event(
        %{
          type: :state_change,
          entity_id: @relay_event,
          attributes: %{"event_type" => "toggle"}
        },
        state
      ) do
    call_service("switch.toggle", %{entity_id: @relay})
    {:ok, state}
  end

  def handle_event(_event, state), do: {:ok, state}
end
