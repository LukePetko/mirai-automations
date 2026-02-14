defmodule Mirai.Automations.Text do
  @moduledoc """
  Test Button automation.
  """
  use Mirai.Automation

  @office_desk_lights ["light.luky_top", "light.niki_top", "light.table_lamp_color"]
  @office_top_lights ["light.office_top_1", "light.office_top_2_6", "light.office_top_3_5"]

  # "on" action -> Toggle office lights
  def handle_event(%{entity_id: "event.bilresa_scroll_wheel_button_3"}, state) do
    Logger.info("Button pressed", state)

    {:ok, state}
  end

  def handle_event(_event, state), do: {:ok, state}
end
