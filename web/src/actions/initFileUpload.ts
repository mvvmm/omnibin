"use server";

import { MAX_FILE_SIZE } from "@/constants/constants";
import { getAccessTokenOrReauth } from "@/lib/auth0";
import { OMNIBIN_API_ROUTES } from "@/routes";
import type { InitFileUploadResult } from "@/types/upload";

export async function initFileUpload(metadata: {
	originalName: string;
	contentType: string;
	size: number;
	imageWidth?: number;
	imageHeight?: number;
}): Promise<InitFileUploadResult> {
	if (metadata.size > MAX_FILE_SIZE) {
		return {
			success: false,
			error: `${(metadata.size / 1024 / 1024).toFixed(2)}MB file size exceeds the ${MAX_FILE_SIZE / 1024 / 1024}MB limit`,
		};
	}

	try {
		const token = await getAccessTokenOrReauth();
		const initUrl = new URL(
			OMNIBIN_API_ROUTES.BIN,
			process.env.NEXT_PUBLIC_BASE_URL,
		);
		const initRes = await fetch(initUrl, {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
				Authorization: `Bearer ${token}`,
			},
			body: JSON.stringify({ file: metadata }),
		});

		if (!initRes.ok) {
			const data = (await initRes.json().catch(() => ({}))) as {
				error?: string;
			};
			return {
				success: false,
				error: data.error || `Failed to init upload (${initRes.status})`,
			};
		}

		const { uploadUrl } = (await initRes.json()) as { uploadUrl: string };
		return { success: true, uploadUrl };
	} catch (e) {
		return { success: false, error: (e as Error).message };
	}
}
