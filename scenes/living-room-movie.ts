import type { AutomationContext, SceneEntities } from "mirai";

export default async function livingRoomMovie({
	homeassistant,
	kv,
}: AutomationContext<"homeassistant" | "kv">) {
	console.log("[mirai] setting living room scene to movie");
	await kv.set("living_room:scene", "movie");
	const isTvPlaying = homeassistant.getState(
		"media_player.living_room_tv_living_room_tv",
	);

	console.log(isTvPlaying);

	const entities: SceneEntities = {
		"light.living_room_main": {
			state: "off",
		},
		"light.dining_room_lights": { state: "off" },
	};
}
