import type { AutomationContext, SceneEntities } from "mirai";

export default async function officeOff({
	homeassistant,
	kv,
}: AutomationContext<"homeassistant" | "kv">) {
	console.log("[mirai] setting office scene to focus");
	await kv.set("office:scene", "off");

	const entities: SceneEntities = {
		"light.office_top_light_white": {
			state: "off",
		},
		"light.office_top_light_rgb": {
			state: "off",
		},
		"light.desk_lamp_color": {
			state: "off",
		},
		"light.desk_crystal_lamp_crystal_lamp": {
			state: "off",
		},
		"light.office_billy_led_main": { state: "off" },
	};

	await homeassistant.callService("scene", "apply", undefined, {
		entities,
		transition: 1,
	});
}
