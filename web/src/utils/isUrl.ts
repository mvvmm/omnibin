export function isUrl(candidate: string): boolean {
	if (typeof candidate !== "string") return false;
	const text = candidate.trim();
	if (text.length === 0) return false;
	// Quick precheck to avoid try/catch cost
	if (!/^https?:\/\//i.test(text)) return false;
	try {
		const url = new URL(text);
		return url.protocol === "http:" || url.protocol === "https:";
	} catch {
		return false;
	}
}

export function extractFirstUrl(text: string): string | null {
	if (typeof text !== "string") return null;
	// Simple regex to find first http/https URL
	const match = text.match(/https?:\/\/[^\s]+/i);
	return match ? match[0] : null;
}
