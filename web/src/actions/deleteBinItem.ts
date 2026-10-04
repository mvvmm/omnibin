import { apiFetch } from "@/lib/api-client";
import { OMNIBIN_API_ROUTES } from "@/routes";

export async function deleteBinItem(itemId: string) {
  try {
    const url = OMNIBIN_API_ROUTES.BIN_ITEM({ itemId });
    const res = await apiFetch(url, {
      method: "DELETE",
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
