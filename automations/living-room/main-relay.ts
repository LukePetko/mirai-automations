import { defineAutomation } from "mirai";
import livingRoomFocus from "../../scenes/living-room-focus";
import livingRoomOff from "../../scenes/living-room-off";

export default defineAutomation({
	require: ["homeassistant", "kv"],
	f: async function livingRoomMainRelay(e, ctx) {
		const relay =
			e.entity_id === "event.living_room_main_relay_action" &&
			e.new_state?.attributes.event_type === "toggle";
		const niki =
			e.entity_id === "event.niki_button_action" &&
			e.new_state?.attributes.event_type === "single";

		if (!relay && !niki) return;

		const livingRoomScene = await ctx.kv.get<string>("living_room:scene");

		console.log(livingRoomScene);

		if (livingRoomScene === "focus") livingRoomOff(ctx);
		else await livingRoomFocus(ctx);
	},
});
