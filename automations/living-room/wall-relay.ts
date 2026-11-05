import { defineAutomation } from "mirai";
import livingRoomMovie from "../../scenes/living-room-movie";

export default defineAutomation({
	require: ["homeassistant", "kv"],
	f: async function livingRoomWallRelay(e, ctx) {
		const relay =
			e.entity_id === "event.living_room_side_relay_action" &&
			e.new_state?.attributes.event_type === "toggle";
		const niki =
			e.entity_id === "event.niki_button_action" &&
			e.new_state?.attributes.event_type === "single";

		if (!relay && !niki) return;

		livingRoomMovie(ctx);

		// await Promise.all([
		// 	ctx.homeassistant.callService(
		// 		"light",
		// 		"toggle",
		// 		{ entity_id: "light.stockholm" },
		// 		{ color_temp_kelvin: 2000, brightness_pct: 10 },
		// 	),
		// 	ctx.homeassistant.callService(
		// 		"light",
		// 		"toggle",
		// 		{ entity_id: "light.living_room_side" },
		// 		{ color_temp_kelvin: 2000, brightness_pct: 40 },
		// 	),
		// ]);
	},
});
