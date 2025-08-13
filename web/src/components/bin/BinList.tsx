"use client";

import { Check, Copy, Download, Loader2, Trash2 } from "lucide-react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import type { BinItem } from "@/types/bin";

export function BinList({ items, token }: { items: BinItem[]; token: string }) {
	const router = useRouter();
	const [deletingId, setDeletingId] = useState<string | null>(null);
	const [errorById, setErrorById] = useState<
		Record<string, string | undefined>
	>({});
	const [copiedId, setCopiedId] = useState<string | null>(null);
	const [downloadingId, setDownloadingId] = useState<string | null>(null);

	const [previewUrlById, setPreviewUrlById] = useState<
		Record<string, string | null>
	>({});

	useEffect(() => {
		let isCancelled = false;
		async function fetchPreviews() {
			const candidates = items.filter(
				(i) =>
					i.kind === "FILE" &&
					i.fileItem &&
					i.fileItem.contentType.startsWith("image/"),
			);
			for (const item of candidates) {
				if (previewUrlById[item.id] !== undefined) continue;
				try {
					const res = await fetch(`/api/bin/${item.id}`, {
						method: "GET",
						headers: { Authorization: `Bearer ${token}` },
					});
					if (!res.ok) throw new Error(`Failed to get preview (${res.status})`);
					const data = (await res.json()) as { url?: string };
					if (!isCancelled) {
						setPreviewUrlById((prev) => ({
							...prev,
							[item.id]: data.url ?? null,
						}));
					}
				} catch {
					if (!isCancelled) {
						setPreviewUrlById((prev) => ({ ...prev, [item.id]: null }));
					}
				}
			}
		}
		fetchPreviews();
		return () => {
			isCancelled = true;
		};
	}, [items, token, previewUrlById]);

	function formatFileSize(size: string | number): string {
		const raw = typeof size === "string" ? Number.parseInt(size, 10) : size;
		if (!Number.isFinite(raw)) return String(size);
		let value = raw as number;
		const units = ["B", "KB", "MB", "GB", "TB"] as const;
		let unitIndex = 0;
		while (value >= 1024 && unitIndex < units.length - 1) {
			value /= 1024;
			unitIndex += 1;
		}
		const digits = value >= 10 || unitIndex === 0 ? 0 : 1;
		return `${value.toFixed(digits)} ${units[unitIndex]}`;
	}

	async function handleCopyImage(
		id: string,
		imageUrl: string,
		fallbackContentType: string,
	) {
		try {
			const res = await fetch(imageUrl);
			if (!res.ok) throw new Error(`Fetch preview failed (${res.status})`);
			const blob = await res.blob();
			const mime = blob.type || fallbackContentType || "image/png";
			await navigator.clipboard.write([new ClipboardItem({ [mime]: blob })]);
			setCopiedId(id);
			setTimeout(
				() => setCopiedId((prev) => (prev === id ? null : prev)),
				1200,
			);
		} catch (error) {
			const err = error as Error;
			setErrorById((prev) => ({ ...prev, [id]: err.message }));
		}
	}

	async function handleCopyFile(id: string, expectedContentType?: string) {
		try {
			// Always fetch a fresh URL to avoid 403 due to expiry
			const r = await fetch(`/api/bin/${id}`, {
				method: "GET",
				headers: { Authorization: `Bearer ${token}` },
			});
			if (!r.ok) throw new Error(`Failed to get file URL (${r.status})`);
			const d = (await r.json()) as { url?: string };
			if (!d.url) throw new Error("Missing file URL");
			setPreviewUrlById((prev) => ({ ...prev, [id]: d.url ?? null }));

			const res = await fetch(d.url);
			if (!res.ok) throw new Error(`Fetch file failed (${res.status})`);
			const blob = await res.blob();
			const mime =
				blob.type || expectedContentType || "application/octet-stream";
			// Write the file blob to clipboard
			await navigator.clipboard.write([new ClipboardItem({ [mime]: blob })]);
			setCopiedId(id);
			setTimeout(
				() => setCopiedId((prev) => (prev === id ? null : prev)),
				1200,
			);
		} catch (error) {
			const err = error as Error;
			setErrorById((prev) => ({ ...prev, [id]: err.message }));
		}
	}

	async function handleDownloadFile(id: string, suggestedName?: string) {
		setErrorById((prev) => ({ ...prev, [id]: undefined }));
		setDownloadingId(id);
		try {
			const r = await fetch(`/api/bin/${id}`, {
				method: "GET",
				headers: { Authorization: `Bearer ${token}` },
			});
			if (!r.ok) throw new Error(`Failed to get file URL (${r.status})`);
			const d = (await r.json()) as { url?: string };
			if (!d.url) throw new Error("Missing file URL");
			const res = await fetch(d.url);
			if (!res.ok) throw new Error(`Fetch file failed (${res.status})`);
			const blob = await res.blob();
			const objectUrl = URL.createObjectURL(blob);
			const a = document.createElement("a");
			a.href = objectUrl;
			a.download = suggestedName || "download";
			document.body.appendChild(a);
			a.click();
			a.remove();
			URL.revokeObjectURL(objectUrl);
		} catch (error) {
			const err = error as Error;
			setErrorById((prev) => ({ ...prev, [id]: err.message }));
		} finally {
			setDownloadingId(null);
		}
	}

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
					<div className="flex items-center justify-between gap-3">
						<div className="min-w-0 flex-1">
							<div className="truncate font-medium text-foreground">
								{item.kind === "TEXT" && item.textItem
									? item.textItem.content
									: item.kind === "FILE" && item.fileItem
										? item.fileItem.originalName
										: ""}
							</div>
							{item.kind === "FILE" &&
								item.fileItem &&
								item.fileItem.contentType.startsWith("image/") && (
									<div className="mt-2">
										{previewUrlById[item.id] && (
											<Image
												src={previewUrlById[item.id] ?? ""}
												alt={item.fileItem.originalName}
												width={item.fileItem.imageWidth ?? 320}
												height={item.fileItem.imageHeight ?? 240}
												className="h-auto max-h-80 w-auto rounded"
												quality={50}
											/>
										)}
									</div>
								)}
							<div className="mt-1 text-xs text-muted-foreground">
								<span>{new Date(item.createdAt).toLocaleString()}</span>
								{item.kind === "FILE" && item.fileItem ? (
									<>
										{" · "}
										<span>{item.fileItem.contentType}</span>
										{" · "}
										<span>{formatFileSize(item.fileItem.size)}</span>
									</>
								) : null}
								{item.kind === "TEXT" && item.textItem ? (
									<>
										{" · "}
										<span>{item.textItem.content.length} chars</span>
									</>
								) : null}
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
							{item.kind === "FILE" &&
							item.fileItem &&
							item.fileItem.contentType.startsWith("image/") ? (
								<Button
									variant="ghost"
									size="icon"
									className="text-muted-foreground hover:text-primary hover:bg-primary/10"
									aria-label="Copy image to clipboard"
									title="Copy image"
									disabled={!previewUrlById[item.id]}
									onClick={() =>
										(async () => {
											const initialUrl = previewUrlById[item.id] as
												| string
												| undefined;
											let url = initialUrl;
											if (!url) return;
											// Try once; on 403, refresh URL then retry
											const res = await fetch(url, { method: "HEAD" });
											if (res.status === 403) {
												const r = await fetch(`/api/bin/${item.id}`, {
													method: "GET",
													headers: { Authorization: `Bearer ${token}` },
												});
												if (r.ok) {
													const d = (await r.json()) as { url?: string };
													if (d.url) {
														setPreviewUrlById((prev) => ({
															...prev,
															[item.id]: d.url ?? null,
														}));
														url = d.url;
													}
												}
											}
											if (!url) return;
											await handleCopyImage(
												item.id,
												url,
												item.fileItem?.contentType ?? "image/png",
											);
										})()
									}
								>
									{copiedId === item.id ? (
										<Check className="h-4 w-4 text-emerald-600" />
									) : (
										<Copy className="h-4 w-4" />
									)}
								</Button>
							) : item.kind === "FILE" && item.fileItem ? (
								<Button
									variant="ghost"
									size="icon"
									className="text-muted-foreground hover:text-primary hover:bg-primary/10"
									aria-label="Copy file to clipboard"
									title="Copy file"
									onClick={() =>
										handleCopyFile(item.id, item.fileItem?.contentType)
									}
								>
									{copiedId === item.id ? (
										<Check className="h-4 w-4 text-emerald-600" />
									) : (
										<Copy className="h-4 w-4" />
									)}
								</Button>
							) : null}
							{item.kind === "FILE" && item.fileItem ? (
								<Button
									variant="ghost"
									size="icon"
									className="text-muted-foreground hover:text-primary hover:bg-primary/10"
									aria-label="Download file"
									title="Download"
									disabled={downloadingId === item.id}
									onClick={() =>
										handleDownloadFile(item.id, item.fileItem?.originalName)
									}
								>
									{downloadingId === item.id ? (
										<Loader2 className="h-4 w-4 animate-spin" />
									) : (
										<Download className="h-4 w-4" />
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
