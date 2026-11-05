import type { SceneEntities } from "mirai";

export function movieLighting(playing: boolean): SceneEntities {
	return playing
		? {
				"light.living_room_tv_led": { state: "off" },
				"light.living_room_side": {
					state: "on",
					brightness: 77,
					color_temp_kelvin: 2000,
				},
				"light.stockholm": {
					state: "on",
					brightness: 26,
					color_temp_kelvin: 2000,
				},
			}
		: {
				"light.living_room_tv_led": {
					state: "on",
					brightness: 102,
					color_temp_kelvin: 3000,
				},
				"light.living_room_side": {
					state: "on",
					brightness: 102,
					color_temp_kelvin: 2000,
				},
				"light.stockholm": {
					state: "on",
					brightness: 51,
					color_temp_kelvin: 2000,
				},
			};
}
