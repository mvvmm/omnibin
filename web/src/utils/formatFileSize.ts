export const formatFileSize = (size: string | number): string => {
	const raw = typeof size === "string" ? Number.parseInt(size, 10) : size;
	if (!Number.isFinite(raw)) return String(size);
	let value = raw as number;
	const units = ["B", "KB", "MB", "GB", "TB"] as const;
	let unitIndex = 0;
	while (value >= 1024 && unitIndex < units.length - 1) {
		value /= 1024;
		unitIndex += 1;
	}
	const digits = value >= 10 || unitIndex === 0 ? 0 : 1;
	return `${value.toFixed(digits)} ${units[unitIndex]}`;
};
