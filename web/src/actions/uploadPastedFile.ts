"use server";

import { MAX_FILE_SIZE } from "@/constants/constants";
import { getAccessTokenOrReauth } from "@/lib/auth0";
import { OMNIBIN_API_ROUTES } from "@/routes";

export async function uploadPastedFile(formData: FormData) {
  const token = await getAccessTokenOrReauth();

  const file = formData.get("file");
  if (!(file instanceof File)) {
    return { success: false, error: "Missing file" } as const;
  }

  if (file.size > MAX_FILE_SIZE) {
    return {
      success: false,
      error: `${(file.size / 1024 / 1024).toFixed(2)}MB file size exceeds the ${MAX_FILE_SIZE / 1024 / 1024}MB limit`,
    } as const;
  }

  const imageWidthRaw = formData.get("imageWidth");
  const imageHeightRaw = formData.get("imageHeight");

  const imageWidth = imageWidthRaw ? Number(imageWidthRaw) : undefined;
  const imageHeight = imageHeightRaw ? Number(imageHeightRaw) : undefined;

  const meta = {
    originalName: file.name || "pasted-file",
    contentType: file.type || "application/octet-stream",
    size: file.size,
    imageWidth,
    imageHeight,
  } as const;

  try {
    const initUrl = new URL(OMNIBIN_API_ROUTES.BIN, process.env.NEXT_PUBLIC_BASE_URL);
    const initRes = await fetch(initUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ file: meta }),
    });
    if (!initRes.ok) {
      const data = (await initRes.json().catch(() => ({}))) as { error?: string };
      return {
        success: false,
        error: data.error || `Failed to init upload (${initRes.status})`,
      } as const;
    }

    const { uploadUrl } = (await initRes.json()) as { uploadUrl: string };

    const putRes = await fetch(uploadUrl, {
      method: "PUT",
      headers: { "Content-Type": meta.contentType },
      body: file,
    });
    if (!putRes.ok) {
      return {
        success: false,
        error: `Failed to upload to storage (${putRes.status})`,
      } as const;
    }

    return { success: true } as const;
  } catch (e) {
    return { success: false, error: (e as Error).message } as const;
  }
}


