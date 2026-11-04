import { defineAutomation } from "mirai";

export default defineAutomation({
	require: ["homeassistant"],
	f: async function kitchenLedRelay(e, ctx) {
		if (e.entity_id !== "event.kitchen_led_relay_action") return;
		if (e.new_state?.attributes.event_type !== "toggle") return;

		await ctx.homeassistant.callService(
			"light",
			"toggle",
			{ entity_id: "light.kitchen_kitchen_led" },
			{ color_temp_kelvin: 3528 },
		);
	},
});
