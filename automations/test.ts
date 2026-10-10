import { defineAutomation } from "mirai";

export default defineAutomation({
	require: ["homeassistant"],
	f: function test(e, ctx) {
		if (
			e.entity_id === "sensor.0x84ba20fffe97b036_action" &&
			e.new_state?.state === "on"
		) {
			console.log(e);
			ctx.homeassistant.callService(
				"light",
				"toggle",
				{
					entity_id: [
						"light.office_top_light_white",
						"light.office_top_light_rgb",
					],
				}, // target: the "who"
			);
		}
	},
});
