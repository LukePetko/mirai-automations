import { defineAutomation } from "mirai";

export default defineAutomation({
	require: ["homeassistant"],
	f: async function bedroomRelay(e, ctx) {
		if (e.entity_id !== "event.0xc02cedfffe30de1d_action") return;
		if (!e.old_state || !e.new_state) return;
		if (e.old_state.state === "unavailable" || e.new_state.state === "unavailable") return;

		await ctx.homeassistant.callService("light", "toggle", {
			entity_id: "light.bedroom_main",
		});
	},
});
