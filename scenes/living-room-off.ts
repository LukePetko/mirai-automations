import type { AutomationContext } from "mirai";

export default async function livingRoomOff({
	homeassistant,
	kv,
}: AutomationContext<"homeassistant" | "kv">) {
	await homeassistant.callService("light", "turn_off", {
		entity_id: ["light.living_room_main"],
	});

	await kv.set("living_room:scene", "off");
}
