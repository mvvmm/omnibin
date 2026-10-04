import { apiFetch } from "@/lib/api-client";
import { OMNIBIN_API_ROUTES } from "@/routes";

export async function deleteAccount() {
  try {
    const url = OMNIBIN_API_ROUTES.ACCOUNT_DELETE;

    const res = await apiFetch(url, {
      method: "DELETE",
    });

    if (!res.ok) {
      const data = (await res.json().catch(() => ({}))) as { error?: string };
      throw new Error(data.error || `Failed to delete account (${res.status})`);
    }

    const result = (await res.json()) as { message: string };
    return { success: true, message: result.message };
  } catch (err) {
    const error = err as Error;
    return { error: error.message, success: false };
  }
}
