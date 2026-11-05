import { defineAutomation } from "mirai";

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

		const currentState = await ctx.kv.get<string>("living_room_state");

		console.log(currentState);

		// await ctx.homeassistant.callService("light", "toggle", {
		// 	entity_id: "light.living_room_main",
		// });
	},
});
