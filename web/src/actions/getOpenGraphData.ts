"use server";

import { getAccessTokenOrReauth } from "@/lib/auth0";
import { OMNIBIN_API_ROUTES } from "@/routes";

export type OgData = {
	url: string;
	title?: string | null;
	description?: string | null;
	image?: string | null;
	icon?: string | null;
	siteName?: string | null;
};

export async function getOpenGraphData(url: string) {
	const token = await getAccessTokenOrReauth();
	try {
		const endpoint = new URL(
			OMNIBIN_API_ROUTES.OG,
			process.env.NEXT_PUBLIC_BASE_URL,
		);
		const res = await fetch(endpoint, {
			method: "POST",
			headers: {
				Authorization: `Bearer ${token}`,
				"content-type": "application/json",
			},
			body: JSON.stringify({ url }),
		});
		if (!res.ok) {
			return {
				success: false,
				error: `OG fetch failed (${res.status})`,
			} as const;
		}
		const data = (await res.json()) as { og?: Omit<OgData, "url"> };
		return {
			success: true,
			og: { url, ...(data.og ?? {}) } as OgData,
		} as const;
	} catch (e) {
		return { success: false, error: (e as Error).message } as const;
	}
}
