import { defineAutomation } from "mirai";
import livingRoomMovie from "../../scenes/living-room-movie";
import livingRoomOff from "../../scenes/living-room-off";

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

		const livingRoomScene = await ctx.kv.get<string>("living_room:scene");

		if (livingRoomScene === "movie") livingRoomOff(ctx);
		else await livingRoomMovie(ctx);
	},
});
