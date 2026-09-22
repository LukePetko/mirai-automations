defmodule Mirai.Automations.Button.Niki do
  @moduledoc """
  Toggles the office top white light on each single press of Niki's button.
  """

  use Mirai.Automation

  @button_event "event.niki_button_action"
  @light "light.office_top_light_white"

  @impl Mirai.Automation
  def handle_event(
        %{
          type: :state_change,
          entity_id: @button_event,
          attributes: %{"event_type" => "single"}
        },
        state
      ) do
    call_service("light.toggle", %{entity_id: @light})
    {:ok, state}
  end

  def handle_event(_event, state), do: {:ok, state}
end
