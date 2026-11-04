import { defineAutomation } from "mirai";

export default defineAutomation({
	require: ["homeassistant", "kv"],
	f: async function test(e, ctx) {
		if (
			e.entity_id === "sensor.0x84ba20fffe97b036_action" &&
			e.new_state?.state === "on"
		) {
			// console.log(e);
			console.log(
				"!!!",
				ctx.homeassistant.getState("light.living_room_tv_led"),
			);
			await ctx.homeassistant.callService(
				"light",
				"toggle",
				{
					entity_id: [
						"light.dining_room_light_1",
						"light.dining_room_light_2",
						"light.dining_room_light_3",
					],
				}, // target: the "who"
				{
					brightness_pct: 5,
				},
			);
		}
	},
});
