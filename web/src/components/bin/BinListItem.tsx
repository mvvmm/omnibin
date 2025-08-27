"use client";

import { Check, Copy, Download, Loader2, Trash2 } from "lucide-react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { useEffect, useState, useTransition } from "react";
import { deleteBinItem } from "@/actions/deleteBinItem";
import { getFileItemDownloadUrl } from "@/actions/getFileItemDownloadUrl";
import { OMNIBIN_API_ROUTES } from "@/routes";
import type { BinItem } from "@/types/bin";
import { formatFileSize } from "@/utils/formatFileSize";
import { isCopyableFile } from "@/utils/isCopyableFile";
import { Button } from "../ui/button";

// TODO: Remove token, use actions
export function BinListItem({ item, token }: { item: BinItem; token: string }) {
	const router = useRouter();

	const [error, setError] = useState<string | null>(null);
	const [copied, setCopied] = useState<boolean | null>(null);

	const [deleteIsTransitioning, startDeleteTransition] = useTransition();
	const [downloadIsTransitioning, startDownloadTransition] = useTransition();
	const [copyIsTransitioning, startCopyingTransition] = useTransition();

	useEffect(() => {
		if (copied) {
			setTimeout(() => setCopied((prev) => (prev ? null : prev)), 1200);
		}
	}, [copied]);

	const handleDelete = async (id: string) => {
		startDeleteTransition(async () => {
			try {
				setError(null);
				const { success, error } = await deleteBinItem(id);

				if (success) {
					router.refresh();
				} else {
					setError(error || "Failed to delete");
				}
			} catch (err) {
				const error = err as Error;
				setError(error.message);
			}
		});
	};

	const handleCopyText = async (text: string) => {
		try {
			setError(null);
			await navigator.clipboard.writeText(text);
			setCopied(true);
		} catch (error) {
			const err = error as Error;
			setError(err.message);
		}
	};

	const handleDownloadFile = async (id: string, suggestedName?: string) => {
		startDownloadTransition(async () => {
			try {
				setError(null);
				const { success, error, downloadUrl } =
					await getFileItemDownloadUrl(id);
				if (!success) {
					setError(error || "Failed to get file URL");
					return;
				}
				if (!downloadUrl) {
					setError("Missing file URL");
					return;
				}
				const res = await fetch(downloadUrl);
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
			} catch (err) {
				const error = err as Error;
				setError(error.message);
			}
		});
	};

	const handleCopyFile = async (
		id: string,
		expectedContentType?: string,
		existingUrl?: string,
	) => {
		startCopyingTransition(async () => {
			try {
				setError(null);
				let url = existingUrl;

				if (!url) {
					const { success, error, downloadUrl } =
						await getFileItemDownloadUrl(id);
					if (!success) {
						setError(error || "Failed to get file URL");
						return;
					} else {
						url = downloadUrl;
					}
					// Update the preview URL for future use
					if (item.fileItem) {
						item.fileItem.preview = url;
					}
				}

				if (!url) {
					setError("No URL available");
					return;
				}

				const res = await fetch(url);
				if (!res.ok) throw new Error(`Fetch file failed (${res.status})`);
				const blob = await res.blob();
				const mime =
					blob.type || expectedContentType || "application/octet-stream";

				// Write the file blob to clipboard
				await navigator.clipboard.write([new ClipboardItem({ [mime]: blob })]);
				setCopied(true);
			} catch (err) {
				const error = err as Error;
				setError(error.message);
			}
		});
	};

	if (deleteIsTransitioning) {
		return null;
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
							disabled={copyIsTransitioning}
							onClick={() =>
								item.textItem && handleCopyText(item.textItem.content)
							}
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
					isCopyableFile(item.fileItem.contentType) ? (
						<Button
							variant="ghost"
							size="icon"
							className="text-muted-foreground hover:text-primary hover:bg-primary/10"
							aria-label="Copy file to clipboard"
							title="Copy file"
							disabled={
								item.fileItem.contentType.startsWith("image/") &&
								!item.fileItem?.preview
							}
							onClick={() =>
								(async () => {
									if (item.fileItem?.contentType.startsWith("image/")) {
										// For images, try to use cached preview URL first
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
										await handleCopyFile(
											item.id,
											item.fileItem?.contentType ?? "image/png",
											url,
										);
									} else {
										// For non-image files, fetch fresh URL
										await handleCopyFile(
											item.id,
											item.fileItem?.contentType,
											undefined,
										);
									}
								})()
							}
						>
							{copyIsTransitioning ? (
								<Loader2 className="h-4 w-4 animate-spin" />
							) : copied ? (
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
							disabled={downloadIsTransitioning}
							onClick={() =>
								handleDownloadFile(item.id, item.fileItem?.originalName)
							}
						>
							{downloadIsTransitioning ? (
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
						onClick={() => handleDelete(item.id)}
					>
						<Trash2 className="h-4 w-4" />
					</Button>
				</div>
			</div>
		</li>
	);
}
