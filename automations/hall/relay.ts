import { defineAutomation } from "mirai";

export default defineAutomation({
	require: ["homeassistant"],
	f: async function hallRelay(e, ctx) {
		if (e.entity_id !== "event.hall_relay_action") return;
		if (e.new_state?.attributes.event_type !== "toggle") return;
		if (
			e.old_state?.state === "unavailable" ||
			e.new_state.state === "unavailable"
		)
			return;

		await ctx.homeassistant.callService("light", "toggle", {
			entity_id: "light.hall_light",
		});
	},
});
