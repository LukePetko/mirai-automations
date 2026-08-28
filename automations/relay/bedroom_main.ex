defmodule Mirai.Automations.Relay.BedroomMain do
  @moduledoc """
  Toggles the main bedroom light when its relay changes state.
  """

  use Mirai.Automation

  @relay_event "event.0xc02cedfffe30de1d_action"
  @light "light.bedroom_main"

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
