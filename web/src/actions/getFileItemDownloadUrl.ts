import { apiFetch } from "@/lib/api-client";
import { OMNIBIN_API_ROUTES } from "@/routes";

export async function getFileItemDownloadUrl(itemId: string) {
  try {
    const url = OMNIBIN_API_ROUTES.BIN_ITEM({ itemId });
    const res = await apiFetch(url, {
      method: "GET",
    });
    if (!res.ok) {
      return {
        success: false,
        error: `Failed to get file URL (${res.status})`,
      };
    }
    const data = (await res.json()) as { url?: string };
    if (!data.url) {
      return { success: false, error: "Missing file URL" };
    }

    return { success: true, downloadUrl: data.url };
  } catch (err) {
    const error = err as Error;
    return { error: error.message, success: false };
  }
}
