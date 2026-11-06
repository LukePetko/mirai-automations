import type { AutomationContext } from "mirai";
import { movieLighting } from "../../helpers/movieLighting";

export default async function livingRoomMovie({
	homeassistant,
	kv,
}: AutomationContext<"homeassistant" | "kv">) {
	console.log("[mirai] setting living room scene to movie");
	await kv.set("living_room:scene", "movie");

	const playing =
		homeassistant.getState("media_player.living_room_tv_living_room_tv")
			?.state === "playing";

	await homeassistant.callService("scene", "apply", undefined, {
		entities: {
			"light.living_room_main": { state: "off" },
			"light.dining_room_lights": { state: "off" },
			...movieLighting(playing),
		},
		transition: 1,
	});
}
