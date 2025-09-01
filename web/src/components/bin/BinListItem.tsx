"use client";

import { Check, Copy, Download, Loader2, Trash2 } from "lucide-react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { useEffect, useState, useTransition } from "react";
import { deleteBinItem } from "@/actions/deleteBinItem";
import { getFileItemDownloadUrl } from "@/actions/getFileItemDownloadUrl";
import type { BinItem } from "@/types/bin";
import { formatFileSize } from "@/utils/formatFileSize";
import { isCopyableFile } from "@/utils/isCopyableFile";
import { Button } from "../ui/button";

export function BinListItem({ item }: { item: BinItem }) {
	const router = useRouter();

	const [error, setError] = useState<string | null>(null);
	const [copied, setCopied] = useState<boolean | null>(null);
	const [downloaded, setDownloaded] = useState<boolean | null>(null);

	const [deleteIsTransitioning, startDeleteTransition] = useTransition();
	const [downloadIsTransitioning, startDownloadTransition] = useTransition();
	const [copyIsTransitioning, startCopyingTransition] = useTransition();

	useEffect(() => {
		if (copied) {
			setTimeout(() => setCopied((prev) => (prev ? null : prev)), 1200);
		}
	}, [copied]);

	useEffect(() => {
		if (downloaded) {
			setTimeout(() => setDownloaded((prev) => (prev ? null : prev)), 1200);
		}
	}, [downloaded]);

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

	const handleDownloadFile = async (
		id: string,
		suggestedName?: string,
		existingUrl?: string,
	) => {
		startDownloadTransition(async () => {
			try {
				setError(null);
				let res: Response | undefined;

				if (existingUrl) {
					res = await fetch(existingUrl);
					if (!res.ok) {
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
						res = await fetch(downloadUrl);
					}
				}

				if (!res || !res.ok) {
					throw new Error(`Fetch file failed (${res?.status})`);
				}
				const blob = await res.blob();
				const objectUrl = URL.createObjectURL(blob);
				const a = document.createElement("a");
				a.href = objectUrl;
				a.download = suggestedName || "download";
				document.body.appendChild(a);
				a.click();
				a.remove();
				URL.revokeObjectURL(objectUrl);
				setDownloaded(true);
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
				let res: Response | undefined;

				if (existingUrl) {
					res = await fetch(existingUrl);
					if (!res.ok) {
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
						res = await fetch(downloadUrl);
					}
				}

				if (!res || !res.ok) {
					throw new Error(`Fetch file failed (${res?.status})`);
				}
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

	const renderTitle = () => {
		if (item.kind === "TEXT" && item.textItem) {
			return item.textItem.content;
		}
		if (item.kind === "FILE" && item.fileItem) {
			return item.fileItem.originalName;
		}
		return "";
	};

	return (
		<li key={item.id}>
			{/* biome-ignore lint/a11y/noStaticElementInteractions: I do what I want */}
			<div
				className="w-full rounded border p-3 text-foreground hover:scale-[101%] hover:cursor-pointer"
				style={{ backgroundColor: "var(--background)" }}
				onClick={() => {
					if (item.kind === "TEXT" && item.textItem) {
						handleCopyText(item.textItem.content);
					}
					if (item.kind === "FILE" && item.fileItem) {
						handleCopyFile(
							item.id,
							item.fileItem.contentType,
							item.fileItem.preview ?? undefined,
						);
					}
				}}
				onKeyDown={(e) => {
					if (e.key === "Enter" || e.key === " ") {
						if (item.kind === "TEXT" && item.textItem) {
							handleCopyText(item.textItem.content);
						}
						if (item.kind === "FILE" && item.fileItem) {
							handleCopyFile(
								item.id,
								item.fileItem.contentType,
								item.fileItem.preview ?? undefined,
							);
						}
					}
				}}
			>
				<div className="flex items-start justify-between gap-3">
					<div className="truncate font-medium text-foreground">
						{renderTitle()}
					</div>
					<div className="flex items-center gap-1.5">
						{/* Copy Text Button */}
						{item.kind === "TEXT" && item.textItem && (
							<Button
								variant="ghost"
								size="icon"
								className="text-muted-foreground hover:text-primary hover:bg-primary/10"
								aria-label="Copy to clipboard"
								title="Copy"
								disabled={copyIsTransitioning}
								onClick={(e) => {
									e.stopPropagation();
									item.textItem && handleCopyText(item.textItem.content);
								}}
							>
								{copied ? (
									<Check className="h-4 w-4 text-emerald-600" />
								) : (
									<Copy className="h-4 w-4" />
								)}
							</Button>
						)}

						{/* Copy File Button */}
						{item.kind === "FILE" &&
							item.fileItem &&
							isCopyableFile(item.fileItem.contentType) && (
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
									onClick={(e) => {
										e.stopPropagation();
										handleCopyFile(
											item.id,
											item?.fileItem?.contentType,
											item?.fileItem?.preview ?? undefined,
										);
									}}
								>
									{copyIsTransitioning ? (
										<Loader2 className="h-4 w-4 animate-spin" />
									) : copied ? (
										<Check className="h-4 w-4 text-emerald-600" />
									) : (
										<Copy className="h-4 w-4" />
									)}
								</Button>
							)}

						{/* Download File Button */}
						{item.kind === "FILE" && item.fileItem && (
							<Button
								variant="ghost"
								size="icon"
								className="text-muted-foreground hover:text-primary hover:bg-primary/10"
								aria-label="Download file"
								title="Download"
								disabled={downloadIsTransitioning}
								onClick={(e) => {
									e.stopPropagation();
									handleDownloadFile(
										item.id,
										item.fileItem?.originalName,
										item?.fileItem?.preview ?? undefined,
									);
								}}
							>
								{downloadIsTransitioning ? (
									<Loader2 className="h-4 w-4 animate-spin" />
								) : downloaded ? (
									<Check className="h-4 w-4 text-emerald-600" />
								) : (
									<Download className="h-4 w-4" />
								)}
							</Button>
						)}

						{/* Delete Button */}
						<Button
							variant="ghost"
							size="icon"
							className="text-muted-foreground hover:text-red-600 hover:bg-red-600/10"
							aria-label="Delete item"
							title="Delete"
							onClick={(e) => {
								e.stopPropagation();
								handleDelete(item.id);
							}}
						>
							<Trash2 className="h-4 w-4" />
						</Button>
					</div>
				</div>

				<div className="flex items-start justify-start gap-3">
					<div className="min-w-0 flex-1 text-left">
						{item.kind === "FILE" &&
							item.fileItem &&
							item.fileItem.contentType.startsWith("image/") && (
								<div className="mb-4 mt-2">
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
							{item.kind === "FILE" && item.fileItem && (
								<>
									{" · "}
									<span>{item.fileItem.contentType}</span>
									{" · "}
									<span>{formatFileSize(item.fileItem.size)}</span>
								</>
							)}
							{item.kind === "TEXT" && item.textItem && (
								<>
									{" · "}
									<span>{item.textItem.content.length} chars</span>
								</>
							)}
						</div>
						{error && <div className="mt-1 text-xs text-red-600">{error}</div>}
					</div>
				</div>
			</div>
		</li>
	);
}
