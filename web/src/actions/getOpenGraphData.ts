import { apiFetch } from "@/lib/api-client";
import { OMNIBIN_API_ROUTES } from "@/routes";
import type { OgData } from "@/types/og";

export async function getOpenGraphData(url: string) {
  const isTwitch = url.includes("twitch.tv");

  try {
    const endpoint = OMNIBIN_API_ROUTES.OG;
    const res = await apiFetch(endpoint, {
      method: "POST",
      headers: {
        "content-type": "application/json",
      },
      // TODO: Fix this?
      cache: isTwitch ? "no-cache" : "force-cache",
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
