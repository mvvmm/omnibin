"use client";

import { useRouter } from "next/navigation";
import { useRef, useState } from "react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import {
	BIN_ITEMS_LIMIT,
	MAX_CHAR_LIMIT,
	MAX_FILE_SIZE,
} from "@/constants/constants";
import { OMNIBIN_API_ROUTES } from "@/routes";

// TODO: get rid of token, use actions
export function CreateItemForm({
	token,
	numItems,
}: {
	token: string;
	numItems: number;
}) {
	const router = useRouter();
	const [content, setContent] = useState("");
	const [isSubmitting, setIsSubmitting] = useState(false);
	const [error, setError] = useState<string | null>(null);
	const [isDragOver, setIsDragOver] = useState(false);
	const textareaRef = useRef<HTMLTextAreaElement>(null);

	async function uploadPastedFile(file: File) {
		setIsSubmitting(true);
		setError(null);

		try {
			if (file.size > MAX_FILE_SIZE) {
				setError(
					`${(file.size / 1024 / 1024).toFixed(2)}MB file size exceeds the ${MAX_FILE_SIZE / 1024 / 1024}MB limit`,
				);
				return;
			}
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
			const meta = {
				originalName: file.name || "pasted-file",
				contentType: file.type || "application/octet-stream",
				size: file.size,
				imageWidth,
				imageHeight,
			};

			const url = new URL(
				OMNIBIN_API_ROUTES.BIN,
				process.env.NEXT_PUBLIC_BASE_URL,
			);
			const initRes = await fetch(url, {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
					Authorization: `Bearer ${token}`,
				},
				body: JSON.stringify({ file: meta }),
			});
			if (!initRes.ok) {
				const data = (await initRes.json().catch(() => ({}))) as {
					error?: string;
				};
				throw new Error(
					data.error || `Failed to init upload (${initRes.status})`,
				);
			}

			const { uploadUrl } = (await initRes.json()) as {
				uploadUrl: string;
			};

			const putRes = await fetch(uploadUrl, {
				method: "PUT",
				headers: { "Content-Type": meta.contentType },
				body: file,
			});
			if (!putRes.ok) {
				throw new Error(`Failed to upload to storage (${putRes.status})`);
			}

			router.refresh();
		} catch (e) {
			const err = e as Error;
			setError(err.message);
		} finally {
			setIsSubmitting(false);
		}
	}

	async function uploadText(text: string) {
		if (isSubmitting) return;
		setError(null);
		const trimmed = text.trim();
		if (!trimmed) {
			setError("Please enter some content");
			return;
		}

		// Check character limit
		if (trimmed.length > MAX_CHAR_LIMIT) {
			setError(
				`Text content (${trimmed.length} characters) exceeds the ${MAX_CHAR_LIMIT} character limit`,
			);
			return;
		}

		setIsSubmitting(true);
		try {
			const url = new URL(
				OMNIBIN_API_ROUTES.BIN,
				process.env.NEXT_PUBLIC_BASE_URL,
			);
			const res = await fetch(url, {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
					Authorization: `Bearer ${token}`,
				},
				body: JSON.stringify({ content: trimmed }),
			});

			if (!res.ok) {
				const data = (await res.json().catch(() => ({}))) as {
					error?: string;
				};
				throw new Error(data.error || `Failed to create item (${res.status})`);
			}

			setContent("");
			router.refresh();
		} catch (e) {
			const err = e as Error;
			setError(err.message);
		} finally {
			setIsSubmitting(false);
		}
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
					placeholder={isDragOver ? "Drop files here..." : "Paste something..."}
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
				<Button disabled={isSubmitting} type="submit" className="btn-omnibin">
					{isSubmitting ? "Adding..." : "Add"}
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
