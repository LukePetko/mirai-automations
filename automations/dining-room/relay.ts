import { defineAutomation } from "mirai";
import livingRoomMovie from "../../scenes/living-room-movie";

export default defineAutomation({
	require: ["homeassistant", "kv"],
	f: async function diningRoomRelay(e, ctx) {
		const relay =
			e.entity_id === "event.dining_room_relay_action" &&
			e.new_state?.attributes.event_type === "toggle";

		if (!relay) return;

		const livingRoomScene = await ctx.kv.get<string>("living_room:scene");
		const currentDiningRoomScene = ctx.homeassistant.getState(
			"light.dining_room_light_1",
		);

		console.log(currentDiningRoomScene);

		if (
			livingRoomScene === "focus" &&
			currentDiningRoomScene?.attributes.brightness
		) {
		}
		await ctx.homeassistant.callService(
			"light",
			"toggle",
			{
				entity_id: "light.dining_room_lights",
			},
			{
				brightness_pct: 80,
			},
		);
	},
});
