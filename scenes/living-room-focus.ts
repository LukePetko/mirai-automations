import type { AutomationContext } from "mirai";

export default async function livingRoomFocus({
	homeassistant,
	kv,
}: AutomationContext<"homeassistant" | "kv">) {
	await homeassistant.callService(
		"light",
		"turn_on",
		{
			entity_id: ["light.living_room_main"],
		},
		{
			brightness_pct: 75,
			color_temp_kelvin: 2500,
			transition: 1,
		},
	);

	await homeassistant.callService(
		"light",
		"turn_on",
		{
			entity_id: ["light.living_room_side", "light.stockholm"],
		},
		{
			brightness_pct: 45,
			color_temp_kelvin: 2500,
			transition: 1,
		},
	);

	await homeassistant.callService("switch", "turn_off", {
		entity_id: "switch.first_led_hardware_instance_component_usb_capture",
	});

	await homeassistant.callService(
		"light",
		"turn_on",
		{
			entity_id: ["light.living_room_tv_led"],
		},
		{
			brightness_pct: 75,
			color_temp_kelvin: 3200,
			transition: 1,
		},
	);

	const diningRoomScene = await kv.get("dining_room:scene");

	if (diningRoomScene !== "focus") {
		await homeassistant.callService(
			"light",
			"turn_on",
			{
				entity_id: ["light.dining_room_lights"],
			},
			{
				brightness_pct: 30,
				color_temp_kelvin: 2500,
				transition: 1,
			},
		);
	}

	await kv.set("living_room:scene", "focus");
}
