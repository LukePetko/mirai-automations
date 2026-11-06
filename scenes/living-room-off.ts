import type { AutomationContext } from "mirai";

export default async function livingRoomOff({
	homeassistant,
	kv,
}: AutomationContext<"homeassistant" | "kv">) {
	console.log("[mirai] setting living room scene to off");
	await kv.set("living_room:scene", "off");

	await homeassistant.callService(
		"light",
		"turn_off",
		{
			entity_id: [
				"light.living_room_main",
				"light.dining_room_lights",
				"light.living_room_side",
				"light.stockholm",
				"light.living_room_tv_led",
			],
		},
		{ transition: 1 },
	);
}
