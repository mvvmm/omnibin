"use server";

import { getAccessTokenOrReauth } from "@/lib/auth0";
import { OMNIBIN_API_ROUTES } from "@/routes";

export async function deleteAccount() {
	const token = await getAccessTokenOrReauth();

	try {
		const url = new URL(
			OMNIBIN_API_ROUTES.ACCOUNT_DELETE,
			process.env.NEXT_PUBLIC_BASE_URL,
		);

		const res = await fetch(url, {
			method: "DELETE",
			headers: { Authorization: `Bearer ${token}` },
		});

		if (!res.ok) {
			const data = (await res.json().catch(() => ({}))) as { error?: string };
			throw new Error(data.error || `Failed to delete account (${res.status})`);
		}

		const result = await res.json();
		return { success: true, message: result.message };
	} catch (err) {
		const error = err as Error;
		return { error: error.message, success: false };
	}
}
