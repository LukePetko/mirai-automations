import { defineAutomation } from "mirai";
import livingRoomFocus from "../../scenes/living-room/focus";
import livingRoomOff from "../../scenes/living-room/off";

export default defineAutomation({
	require: ["homeassistant", "kv"],
	f: async function livingRoomMainRelay(e, ctx) {
		const relay =
			e.entity_id === "event.living_room_main_relay_action" &&
			e.new_state?.attributes.event_type === "toggle";

		if (!relay) return;

		const livingRoomScene = await ctx.kv.get<string>("living_room:scene");

		if (livingRoomScene === "focus") livingRoomOff(ctx);
		else await livingRoomFocus(ctx);
	},
});
