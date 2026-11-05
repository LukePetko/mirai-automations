import type { AutomationContext } from "mirai";

export default async function livingRoomFocus({
	homeassistant,
	kv,
}: AutomationContext<"homeassistant" | "kv">) {
	const diningRoomScene = await kv.get("dining_room:scene");

	homeassistant.callService(
		"light",
		"turn_on",
		{
			entity_id: ["light.living_room_main"],
		},
		{
			brightness_pct: 75,
			color_temp_kelvin: 2700,
		},
	);

	await kv.set("living_room:scene", "focus");
}
