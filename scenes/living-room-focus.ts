import type { AutomationContext } from "mirai";

export default async function livingRoomFocus({
	homeassistant,
	kv,
}: AutomationContext<"homeassistant" | "kv">) {
	console.log("[mirai] setting living room scene to focus");
	await kv.set("living_room:scene", "focus");
	const diningRoomScene = await kv.get<string>("dining_room:scene");

	const entities: Record<string, Record<string, unknown>> = {
		"light.living_room_main": {
			state: "on",
			brightness_pct: 75,
			color_temp_kelvin: 2500,
		},
		"light.living_room_side": {
			state: "on",
			brightness_pct: 30,
			color_temp_kelvin: 2500,
		},
		"light.stockholm": {
			state: "on",
			brightness_pct: 20,
			color_temp_kelvin: 2500,
		},
		"light.living_room_tv_led": {
			state: "on",
			brightness_pct: 75,
			color_temp_kelvin: 3200,
		},
		"switch.first_led_hardware_instance_component_usb_capture": {
			state: "off",
		},
	};

	if (diningRoomScene !== "focus") {
		entities["light.dining_room_lights"] = {
			state: "on",
			brightness_pct: 30,
			color_temp_kelvin: 2500,
		};
	}

	await homeassistant.callService("scene", "apply", undefined, {
		entities,
		transition: 1,
	});
}
