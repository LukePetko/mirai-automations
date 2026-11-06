import { defineAutomation } from "mirai";
import { movieLighting } from "../../helpers/movieLighting";

export default defineAutomation({
	require: ["homeassistant", "kv"],
	f: async function movieModeMediaPlayer(e, ctx) {
		const changed =
			e.entity_id === "media_player.living_room_tv_living_room_tv" &&
			e.old_state?.state !== e.new_state?.state;

		if (!changed) return;

		const isMovieMode = (await ctx.kv.get("living_room:scene")) === "movie";
		if (!isMovieMode) return;

		await ctx.homeassistant.callService("scene", "apply", undefined, {
			entities: movieLighting(e.new_state?.state === "playing"),
			transition: 1,
		});
	},
});
