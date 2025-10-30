"use client";

import { useRouter } from "next/navigation";
import { useRef, useState, useTransition } from "react";
import { uploadPastedFile as uploadPastedFileAction } from "@/actions/uploadPastedFile";
import { uploadText as uploadTextAction } from "@/actions/uploadText";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { BIN_ITEMS_LIMIT } from "@/constants/constants";

export function CreateItemForm({ numItems }: { numItems: number }) {
	const router = useRouter();
	const [content, setContent] = useState("");
	const [error, setError] = useState<string | null>(null);
	const [isDragOver, setIsDragOver] = useState(false);
	const textareaRef = useRef<HTMLTextAreaElement>(null);
	const [isPending, startTransition] = useTransition();

	async function uploadPastedFile(file: File) {
		setError(null);

		let imageWidth: number | undefined;
		let imageHeight: number | undefined;
		if (file.type.startsWith("image/")) {
			await new Promise<void>((resolve) => {
				const img = new Image();
				img.onload = () => {
					imageWidth = img.naturalWidth || img.width;
					imageHeight = img.naturalHeight || img.height;
					resolve();
				};
				img.onerror = () => resolve();
				img.src = URL.createObjectURL(file);
			});
		}

		const fd = new FormData();
		fd.append("file", file);
		if (imageWidth !== undefined) fd.append("imageWidth", String(imageWidth));
		if (imageHeight !== undefined)
			fd.append("imageHeight", String(imageHeight));

		startTransition(async () => {
			const result = await uploadPastedFileAction(fd);
			if (!result.success) {
				setError(result.error || "Upload failed");
				return;
			}
			router.refresh();
		});
	}

	async function uploadText(text: string) {
		setError(null);
		startTransition(async () => {
			const result = await uploadTextAction(text);
			if (!result.success) {
				setError(result.error || "Failed to add item");
				return;
			}
			setContent("");
			router.refresh();
		});
	}

	async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
		event.preventDefault();
		await uploadText(content);
	}

	async function handlePaste(e: React.ClipboardEvent<HTMLTextAreaElement>) {
		const files = Array.from(e.clipboardData?.files ?? []);
		if (files.length > 0) {
			e.preventDefault();
			for (const file of files) {
				await uploadPastedFile(file);
			}
			return;
		}

		// Fallback to text paste: submit instantly
		const pasted = e.clipboardData.getData("text");
		if (!pasted) return;
		e.preventDefault();
		setContent(pasted);
		await uploadText(pasted);
	}

	function handleDragOver(e: React.DragEvent<HTMLTextAreaElement>) {
		e.preventDefault();
		e.stopPropagation();
		if (!isDragOver) {
			setIsDragOver(true);
		}
	}

	function handleDragEnter(e: React.DragEvent<HTMLTextAreaElement>) {
		e.preventDefault();
		e.stopPropagation();
		setIsDragOver(true);
	}

	function handleDragLeave(e: React.DragEvent<HTMLTextAreaElement>) {
		e.preventDefault();
		e.stopPropagation();
		// Only set isDragOver to false if we're leaving the textarea itself
		if (!e.currentTarget.contains(e.relatedTarget as Node)) {
			setIsDragOver(false);
		}
	}

	async function handleDrop(e: React.DragEvent<HTMLTextAreaElement>) {
		e.preventDefault();
		e.stopPropagation();
		setIsDragOver(false);

		const files = Array.from(e.dataTransfer.files);
		if (files.length > 0) {
			for (const file of files) {
				await uploadPastedFile(file);
			}
		}
	}

	return (
		<form onSubmit={handleSubmit} className="space-y-2">
			<div className="mb-4">
				<Textarea
					ref={textareaRef}
					value={content}
					onChange={(e) => setContent(e.target.value)}
					onPaste={handlePaste}
					onDragOver={handleDragOver}
					onDragEnter={handleDragEnter}
					onDragLeave={handleDragLeave}
					onDrop={handleDrop}
					placeholder={
						isDragOver ? "Drop files here..." : "Paste or drag here..."
					}
					rows={3}
					className={`mb-1 transition-all duration-200 ${
						isDragOver
							? "border-omnibin-primary bg-omnibin-primary/5 ring-2 ring-omnibin-primary/20"
							: ""
					}`}
				/>
				{error && <div className="ml-2 text-sm text-red-600">{error}</div>}
			</div>

			<div className="flex items-end gap-3 justify-between">
				<Button disabled={isPending} type="submit" className="btn-omnibin">
					{isPending ? "Adding..." : "Add"}
				</Button>

				<div className="flex flex-col items-end col-gap-1 mr-1">
					<div
						className={`text-xs text-muted-foreground ${numItems >= BIN_ITEMS_LIMIT && "text-red-600"}`}
					>
						Items: {numItems} / {BIN_ITEMS_LIMIT}
					</div>
					{numItems >= BIN_ITEMS_LIMIT && (
						<div className="text-xs text-red-600">
							Oldest item will be deleted on next add.
						</div>
					)}
				</div>
			</div>
		</form>
	);
}
