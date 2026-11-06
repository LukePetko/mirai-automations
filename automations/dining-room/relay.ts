import { defineAutomation } from "mirai";
import { near } from "../../helpers/near";

export default defineAutomation({
	require: ["homeassistant", "kv"],
	f: async function diningRoomRelay(e, ctx) {
		const relay =
			e.entity_id === "event.dining_room_relay_action" &&
			e.new_state?.attributes.event_type === "toggle";

		if (!relay) return;

		const focus = (await ctx.kv.get<string>("living_room:scene")) === "focus";
		const light = ctx.homeassistant.getState("light.dining_room_lights");
		const brightness = light?.attributes.brightness;

		if (focus && near(brightness, 204)) {
			await ctx.homeassistant.callService(
				"light",
				"turn_on",
				{ entity_id: "light.dining_room_lights" },
				{ brightness_pct: 30 },
			);
		} else if (light?.state === "off" || (focus && near(brightness, 77))) {
			await ctx.homeassistant.callService(
				"light",
				"turn_on",
				{ entity_id: "light.dining_room_lights" },
				{ brightness_pct: 80 },
			);
		} else {
			await ctx.homeassistant.callService("light", "turn_off", {
				entity_id: "light.dining_room_lights",
			});
		}
	},
});
