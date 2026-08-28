defmodule Mirai.Automations.Relay.KitchenLed do
  @moduledoc """
  Toggles the kitchen LED when its relay emits a `toggle` event.
  """

  use Mirai.Automation

  @relay_event "event.kitchen_led_relay_action"
  @light "light.kitchen_kitchen_led"
  @color_temp_kelvin 3528

  @impl Mirai.Automation
  def handle_event(
        %{
          type: :state_change,
          entity_id: @relay_event,
          attributes: %{"event_type" => "toggle"}
        },
        state
      ) do
    call_service("light.toggle", %{
      entity_id: @light,
      color_temp_kelvin: @color_temp_kelvin
    })

    {:ok, state}
  end

  def handle_event(_event, state), do: {:ok, state}
end
