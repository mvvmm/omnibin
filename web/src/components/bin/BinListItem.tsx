"use client";

import { Check, Copy, Download, Loader2, Trash2 } from "lucide-react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { OMNIBIN_API_ROUTES } from "@/routes";
import type { BinItem } from "@/types/bin";
import { Button } from "../ui/button";

// TODO: Remove token, use actions
export function BinListItem({ item, token }: { item: BinItem; token: string }) {
	const router = useRouter();
	const [deleting, setDeleting] = useState<boolean | null>(null);
	const [error, setError] = useState<string | null>(null);
	const [copied, setCopied] = useState<boolean | null>(null);
	const [downloading, setDownloading] = useState<boolean | null>(null);

	async function handleCopy(text: string) {
		try {
			await navigator.clipboard.writeText(text);
			setCopied(true);
			setTimeout(() => setCopied((prev) => (prev ? null : prev)), 1200);
		} catch (error) {
			console.error("Failed to copy to clipboard:", error);
		}
	}

	async function handleDelete(id: string) {
		setError(null);
		setDeleting(true);
		try {
			const url = new URL(
				OMNIBIN_API_ROUTES.BIN_ITEM({ itemId: id }),
				process.env.NEXT_PUBLIC_BASE_URL,
			);
			const res = await fetch(url, {
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
			setError(err.message);
		} finally {
			setDeleting(null);
		}
	}

	async function handleDownloadFile(id: string, suggestedName?: string) {
		setError(null);
		setDownloading(true);
		try {
			const url = new URL(
				OMNIBIN_API_ROUTES.BIN_ITEM({ itemId: id }),
				process.env.NEXT_PUBLIC_BASE_URL,
			);
			const r = await fetch(url, {
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
			setError(err.message);
		} finally {
			setDownloading(null);
		}
	}

	async function handleCopyFile(id: string, expectedContentType?: string) {
		try {
			// Always fetch a fresh URL to avoid 403 due to expiry
			const url = new URL(
				OMNIBIN_API_ROUTES.BIN_ITEM({ itemId: id }),
				process.env.NEXT_PUBLIC_BASE_URL,
			);
			const r = await fetch(url, {
				method: "GET",
				headers: { Authorization: `Bearer ${token}` },
			});
			if (!r.ok) throw new Error(`Failed to get file URL (${r.status})`);
			const d = (await r.json()) as { url?: string };
			if (!d.url) throw new Error("Missing file URL");
			if (item.fileItem) {
				item.fileItem.preview = d.url;
			}

			const res = await fetch(d.url);
			if (!res.ok) throw new Error(`Fetch file failed (${res.status})`);
			const blob = await res.blob();
			const mime =
				blob.type || expectedContentType || "application/octet-stream";
			// Write the file blob to clipboard
			await navigator.clipboard.write([new ClipboardItem({ [mime]: blob })]);
			setCopied(true);
			setTimeout(() => setCopied((prev) => (prev ? null : prev)), 1200);
		} catch (error) {
			const err = error as Error;
			setError(err.message);
		}
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
			setCopied(true);
			setTimeout(() => setCopied((prev) => (prev ? null : prev)), 1200);
		} catch (error) {
			const err = error as Error;
			setError(err.message);
		}
	}

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

	return (
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
								{item.fileItem.preview && (
									<Image
										src={item.fileItem.preview}
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
					{error ? (
						<div className="mt-1 text-xs text-red-600">{error}</div>
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
							onClick={() => item.textItem && handleCopy(item.textItem.content)}
						>
							{copied ? (
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
							disabled={!item.fileItem?.preview}
							onClick={() =>
								(async () => {
									const initialUrl = item.fileItem?.preview as
										| string
										| undefined;
									let url = initialUrl;
									if (!url) return;
									// Try once; on 403, refresh URL then retry
									const res = await fetch(url, { method: "HEAD" });
									if (res.status === 403) {
										const _url = new URL(
											OMNIBIN_API_ROUTES.BIN_ITEM({ itemId: item.id }),
											process.env.NEXT_PUBLIC_BASE_URL,
										);
										const r = await fetch(_url, {
											method: "GET",
											headers: { Authorization: `Bearer ${token}` },
										});
										if (r.ok) {
											const d = (await r.json()) as { url?: string };
											if (d.url) {
												if (item.fileItem) {
													item.fileItem.preview = d.url;
												}
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
							{copied ? (
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
							{copied ? (
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
							disabled={downloading ?? false}
							onClick={() =>
								handleDownloadFile(item.id, item.fileItem?.originalName)
							}
						>
							{downloading ? (
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
						disabled={deleting ?? false}
						onClick={() => handleDelete(item.id)}
					>
						{deleting ? (
							<Loader2 className="h-4 w-4 animate-spin" />
						) : (
							<Trash2 className="h-4 w-4" />
						)}
					</Button>
				</div>
			</div>
		</li>
	);
}
