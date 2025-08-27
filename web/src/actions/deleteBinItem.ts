"use server";

import { getAccessTokenOrReauth } from "@/lib/auth0";
import { OMNIBIN_API_ROUTES } from "@/routes";

export async function deleteBinItem(itemId: string) {
	const token = await getAccessTokenOrReauth();

	try {
		const url = new URL(
			OMNIBIN_API_ROUTES.BIN_ITEM({ itemId }),
			process.env.NEXT_PUBLIC_BASE_URL,
		);
		const res = await fetch(url, {
			method: "DELETE",
			headers: { Authorization: `Bearer ${token}` },
		});
		if (!res.ok && res.status !== 204) {
			const data = (await res.json().catch(() => ({}))) as { error?: string };
			throw new Error(data.error || `Failed to delete (${res.status})`);
		}
		return { success: true };
	} catch (err) {
		const error = err as Error;
		return { error: error.message, success: false };
	}
}
