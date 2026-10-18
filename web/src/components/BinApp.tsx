import { useCallback, useEffect, useState } from "react";
import AppShell from "./AppShell";
import { SiteHeader } from "./site-header";
import { ContextMenu } from "./context-menu";
import { PopupA } from "./popupA";
import { CreateItemForm } from "./bin/CreateItemForm";
import { BinList } from "./bin/BinList";
import BinListLoading from "./bin/BinListLoading";
import { apiFetch } from "@/lib/api-client";
import { ALWAYS_SHOW_POPUP_A } from "@/constants/constants";
import type { BinItem } from "@/types/bin";
export default function BinApp() {
  const [items, setItems] = useState<BinItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>();
  const [popup, setPopup] = useState(false);
  const refresh = useCallback(async () => {
    try {
      const response = await apiFetch("/api/bin");
      if (!response.ok) throw new Error("Failed to load your bin items");
      const data = (await response.json()) as { items: BinItem[] };
      await Promise.all(
        data.items.map(async (item) => {
          if (
            item.kind === "FILE" &&
            item.fileItem?.contentType.startsWith("image/") &&
            !item.fileItem.preview
          ) {
            const result = await apiFetch(`/api/bin/${item.id}`);
            if (result.ok)
              item.fileItem.preview = (
                (await result.json()) as { url: string }
              ).url;
          }
        })
      );
      setItems(data.items);
      setError(undefined);
    } catch (error) {
      setError((error as Error).message);
    } finally {
      setLoading(false);
    }
  }, []);
  useEffect(() => {
    void refresh();
    void apiFetch("/api/user")
      .then(async (response) => {
        if (response.ok)
          setPopup(
            ALWAYS_SHOW_POPUP_A ||
              !(
                (await response.json()) as {
                  user: { ignoreWebPopupA: boolean };
                }
              ).user.ignoreWebPopupA
          );
      })
      .catch(() => {});
    const onRefresh = () => {
      void refresh();
    };
    const onVisible = () => {
      if (document.visibilityState === "visible") void refresh();
    };
    window.addEventListener("bin:refresh", onRefresh);
    window.addEventListener("focus", onRefresh);
    document.addEventListener("visibilitychange", onVisible);
    return () => {
      window.removeEventListener("bin:refresh", onRefresh);
      window.removeEventListener("focus", onRefresh);
      document.removeEventListener("visibilitychange", onVisible);
    };
  }, [refresh]);
  return (
    <AppShell>
      <SiteHeader className="max-w-[672px]">
        <ContextMenu loggedIn />
      </SiteHeader>
      <div className="mx-auto w-full max-w-[672px] space-y-6 px-4 pt-4 pb-16">
        <h1 className="sr-only">Your bin</h1>
        <CreateItemForm numItems={items.length} />
        {error && (
          <p role="alert" className="text-sm text-destructive">
            {error}
          </p>
        )}
        {loading ? <BinListLoading /> : <BinList items={items} />}
      </div>
      {popup && <PopupA />}
    </AppShell>
  );
}
