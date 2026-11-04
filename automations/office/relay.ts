import { defineAutomation } from "mirai";

export default defineAutomation({
	require: ["homeassistant"],
	f: async function officeRelay(e, ctx) {
		if (e.entity_id !== "event.office_relay_action") return;
		if (e.new_state?.attributes.event_type !== "toggle") return;

		await ctx.homeassistant.callService("light", "toggle", {
			entity_id: "light.office_top_light_white",
		});
	},
});
