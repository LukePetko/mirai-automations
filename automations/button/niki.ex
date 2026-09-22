defmodule Mirai.Automations.Button.Niki do
  @moduledoc """
  Toggles the office top white light and notifies Luke's iPhone 16 Pro
  on each single press of Niki's button.
  """

  use Mirai.Automation

  @button_event "event.niki_button_action"
  @light "light.office_top_light_white"
  @notify "notify.mobile_app_lukes_iphone_16_pro"

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

    call_service(@notify, %{
      title: "Niki button",
      message: "Niki's button was pressed."
    })

    {:ok, state}
  end

  def handle_event(_event, state), do: {:ok, state}
end
