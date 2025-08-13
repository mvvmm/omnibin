"use client";

import { Check, Copy, Loader2, Trash2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import type { BinItem } from "@/types/bin";

export function BinList({ items, token }: { items: BinItem[]; token: string }) {
	const router = useRouter();
	const [deletingId, setDeletingId] = useState<string | null>(null);
	const [errorById, setErrorById] = useState<
		Record<string, string | undefined>
	>({});
	const [copiedId, setCopiedId] = useState<string | null>(null);

	async function handleDelete(id: string) {
		setErrorById((prev) => ({ ...prev, [id]: undefined }));
		setDeletingId(id);
		try {
			const res = await fetch(`/api/bin/${id}`, {
				method: "DELETE",
				headers: { Authorization: `Bearer ${token}` },
			});
			if (!res.ok && res.status !== 204) {
				const data = (await res.json().catch(() => ({}))) as { error?: string };
				throw new Error(data.error || `Failed to delete (${res.status})`);
			}

			router.refresh();
		} catch (e) {
			const err = e as Error;
			setErrorById((prev) => ({ ...prev, [id]: err.message }));
		} finally {
			setDeletingId(null);
		}
	}

	async function handleCopy(id: string, text: string) {
		try {
			await navigator.clipboard.writeText(text);
			setCopiedId(id);
			setTimeout(
				() => setCopiedId((prev) => (prev === id ? null : prev)),
				1200,
			);
		} catch (error) {
			console.error("Failed to copy to clipboard:", error);
		}
	}

	if (items.length === 0)
		return <p className="text-muted-foreground">No items yet.</p>;

	return (
		<ul className="space-y-2">
			{items.map((item) => (
				<li
					key={item.id}
					className="rounded border p-3 bg-background/50 text-foreground"
				>
					<div className="flex items-start justify-between gap-3">
						<div className="min-w-0 flex-1">
							<div className="whitespace-pre-wrap break-words text-foreground">
								{item.kind === "TEXT" && item.textItem
									? item.textItem.content
									: item.kind === "FILE" && item.fileItem
										? `${item.fileItem.originalName} (${item.fileItem.contentType}, ${typeof item.fileItem.size === "string" ? item.fileItem.size : `${item.fileItem.size} bytes`})`
										: ""}
							</div>
							<div className="mt-1 text-xs text-muted-foreground">
								{new Date(item.createdAt).toLocaleString()}
							</div>
							{errorById[item.id] ? (
								<div className="mt-1 text-xs text-red-600">
									{errorById[item.id]}
								</div>
							) : null}
						</div>
						<div className="flex items-center gap-1.5">
							{item.kind === "TEXT" && item.textItem ? (
								<Button
									variant="ghost"
									size="icon"
									className="text-muted-foreground hover:text-primary hover:bg-primary/10"
									aria-label="Copy to clipboard"
									title="Copy"
									onClick={() =>
										item.textItem && handleCopy(item.id, item.textItem.content)
									}
								>
									{copiedId === item.id ? (
										<Check className="h-4 w-4 text-emerald-600" />
									) : (
										<Copy className="h-4 w-4" />
									)}
								</Button>
							) : null}
							<Button
								variant="ghost"
								size="icon"
								className="text-muted-foreground hover:text-red-600 hover:bg-red-600/10"
								aria-label="Delete item"
								title="Delete"
								disabled={deletingId === item.id}
								onClick={() => handleDelete(item.id)}
							>
								{deletingId === item.id ? (
									<Loader2 className="h-4 w-4 animate-spin" />
								) : (
									<Trash2 className="h-4 w-4" />
								)}
							</Button>
						</div>
					</div>
				</li>
			))}
		</ul>
	);
}
