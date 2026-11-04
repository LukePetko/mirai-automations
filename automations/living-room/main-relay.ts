import { defineAutomation } from "mirai";

export default defineAutomation({
	require: ["homeassistant"],
	f: async function livingRoomMainRelay(e, ctx) {
		if (e.entity_id !== "event.living_room_main_relay_action") return;
		if (e.new_state?.attributes.event_type !== "toggle") return;

		await ctx.homeassistant.callService("light", "toggle", {
			entity_id: "light.living_room_main",
		});
	},
});
