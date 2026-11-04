import { defineAutomation } from "mirai";

export default defineAutomation({
	require: ["homeassistant"],
	f: async function diningRoomRelay(e, ctx) {
		if (e.entity_id !== "event.dining_room_relay_action") return;
		if (!e.old_state || !e.new_state) return;
		if (e.old_state.state === "unavailable" || e.new_state.state === "unavailable") return;

		await ctx.homeassistant.callService("light", "toggle", {
			entity_id: "light.dining_room_lights",
		});
	},
});
