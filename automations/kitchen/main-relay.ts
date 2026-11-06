import { defineAutomation } from "mirai";

export default defineAutomation({
	require: ["homeassistant"],
	f: async function kitchenMainRelay(e, ctx) {
		const relay =
			e.entity_id === "event.kitchen_main_relay_action" &&
			e.new_state?.attributes.event_type === "toggle";

		if (!relay) return;

		const ledOn =
			ctx.homeassistant.getState("light.kitchen_kitchen_led")?.state === "on";
		const kitchenOn =
			ctx.homeassistant.getState("light.kitchen_main")?.state === "on";

		if (ledOn === kitchenOn)
			await ctx.homeassistant.callService(
				"light",
				"toggle",
				{ entity_id: "light.kitchen_kitchen_led" },
				{ color_temp_kelvin: 3528 },
			);

		await ctx.homeassistant.callService("light", "toggle", {
			entity_id: "light.kitchen_main",
		});
	},
});
