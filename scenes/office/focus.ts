import type { AutomationContext, SceneEntities } from "mirai";

export default async function officeFocus({
	homeassistant,
	kv,
}: AutomationContext<"homeassistant" | "kv">) {
	console.log("[mirai] setting office scene to focus");
	await kv.set("office:scene", "focus");

	const entities: SceneEntities = {
		"light.office_top_light_white": {
			state: "on",
			brightness: 127,
			color_temp_kelvin: 2700,
		},
		"light.office_top_light_rgb": {
			state: "on",
			brightness: 254,
			xy_color: [0.369, 0.101],
		},
		"light.desk_lamp_color": {
			state: "on",
			brightness: 153,
			color_temp_kelvin: 2700,
		},
		"light.desk_crystal_lamp_crystal_lamp": {
			state: "on",
			brightness: 153,
			color_temp_kelvin: 2700,
		},
		"light.office_billy_led_main": { state: "on", brightness: 153 },
		"select.office_billy_led_preset": { state: "Focus" },
	};

	await homeassistant.callService("scene", "apply", undefined, {
		entities,
		transition: 1,
	});
}
