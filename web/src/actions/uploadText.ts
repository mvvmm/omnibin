"use server";

import { MAX_CHAR_LIMIT } from "@/constants/constants";
import { getAccessTokenOrReauth } from "@/lib/auth0";
import { OMNIBIN_API_ROUTES } from "@/routes";

export async function uploadText(text: string) {
	const token = await getAccessTokenOrReauth();

	const trimmed = text.trim();
	if (!trimmed) {
		return { success: false, error: "Paste was empty" } as const;
	}
	if (trimmed.length > MAX_CHAR_LIMIT) {
		return {
			success: false,
			error: `Text content (${trimmed.length} characters) exceeds the ${MAX_CHAR_LIMIT} character limit`,
		} as const;
	}

	try {
		const url = new URL(
			OMNIBIN_API_ROUTES.BIN,
			process.env.NEXT_PUBLIC_BASE_URL,
		);
		const res = await fetch(url, {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
				Authorization: `Bearer ${token}`,
			},
			body: JSON.stringify({ content: trimmed }),
		});

		if (!res.ok) {
			const data = (await res.json().catch(() => ({}))) as { error?: string };
			return {
				success: false,
				error: data.error || `Failed to create item (${res.status})`,
			} as const;
		}

		return { success: true } as const;
	} catch (e) {
		return { success: false, error: (e as Error).message } as const;
	}
}
