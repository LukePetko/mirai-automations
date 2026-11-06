import { defineAutomation } from "mirai";
import officeFocus from "../../scenes/office/focus";
import officeOff from "../../scenes/office/off";

export default defineAutomation({
	require: ["homeassistant", "kv"],
	f: async function officeRelay(e, ctx) {
		const relay =
			e.entity_id === "event.office_relay_action" &&
			e.new_state?.attributes.event_type === "toggle";

		if (!relay) return;

		const officeState = await ctx.kv.get("office:scene");

		switch (officeState) {
			case "focus":
				officeFocus(ctx);
				return;
			case "off":
			default:
				officeOff(ctx);
		}
	},
});
