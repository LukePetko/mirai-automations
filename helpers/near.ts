export function near(value: unknown, target: number) {
	return typeof value === "number" && Math.abs(value - target) <= 3;
}
