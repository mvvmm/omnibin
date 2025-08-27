"use server";

import { getAccessTokenOrReauth } from "@/lib/auth0";
import { OMNIBIN_API_ROUTES } from "@/routes";

export async function getFileItemDownloadUrl(itemId: string) {
	const token = await getAccessTokenOrReauth();

	try {
		const url = new URL(
			OMNIBIN_API_ROUTES.BIN_ITEM({ itemId }),
			process.env.NEXT_PUBLIC_BASE_URL,
		);
		const res = await fetch(url, {
			method: "GET",
			headers: { Authorization: `Bearer ${token}` },
		});
		if (!res.ok) {
			return {
				success: false,
				error: `Failed to get file URL (${res.status})`,
			};
		}
		const data = (await res.json()) as { url?: string };
		if (!data.url) {
			return { success: "false", error: "Missing file URL" };
		}

		return { success: true, downloadUrl: data.url };
	} catch (err) {
		const error = err as Error;
		return { error: error.message, success: false };
	}
}
