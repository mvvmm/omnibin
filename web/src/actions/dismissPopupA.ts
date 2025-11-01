"use server";

import { getAccessTokenOrReauth } from "@/lib/auth0";
import { OMNIBIN_API_ROUTES } from "@/routes";

export async function dismissPopupA() {
	const token = await getAccessTokenOrReauth();

	try {
		const url = new URL(
			OMNIBIN_API_ROUTES.DISMISS_WEB_POPUP_A,
			process.env.NEXT_PUBLIC_BASE_URL,
		);

		const res = await fetch(url, {
			method: "PATCH",
			headers: { Authorization: `Bearer ${token}` },
		});

		if (!res.ok) {
			const data = (await res.json().catch(() => ({}))) as { error?: string };
			throw new Error(data.error || `Failed to dismiss popup (${res.status})`);
		}

		return { success: true };
	} catch (err) {
		const error = err as Error;
		return { error: error.message, success: false };
	}
}
