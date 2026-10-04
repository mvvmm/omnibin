import { apiFetch } from "@/lib/api-client";
import { OMNIBIN_API_ROUTES } from "@/routes";

export async function dismissPopupA() {
  try {
    const url = OMNIBIN_API_ROUTES.DISMISS_WEB_POPUP_A;

    const res = await apiFetch(url, {
      method: "PATCH",
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
