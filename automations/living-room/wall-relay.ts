import { defineAutomation } from "mirai";

export default defineAutomation({
	require: ["homeassistant"],
	f: async function livingRoomWallRelay(e, ctx) {
		if (e.entity_id !== "event.living_room_side_relay_action") return;
		if (!e.old_state || !e.new_state) return;
		if (e.old_state.state === "unavailable" || e.new_state.state === "unavailable") return;

		await Promise.all([
			ctx.homeassistant.callService(
				"light",
				"toggle",
				{ entity_id: "light.stockholm" },
				{ color_temp_kelvin: 2000, brightness_pct: 10 },
			),
			ctx.homeassistant.callService(
				"light",
				"toggle",
				{ entity_id: "light.living_room_side" },
				{ color_temp_kelvin: 2000, brightness_pct: 40 },
			),
		]);
	},
});
