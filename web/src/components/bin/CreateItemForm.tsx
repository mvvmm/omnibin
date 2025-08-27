"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";

type CreateItemFormProps = {
	token: string;
};

export function CreateItemForm({ token }: CreateItemFormProps) {
	const router = useRouter();
	const [content, setContent] = useState("");
	const [isSubmitting, setIsSubmitting] = useState(false);
	const [error, setError] = useState<string | null>(null);

	async function uploadPastedFile(file: File) {
		setIsSubmitting(true);
		setError(null);
		try {
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

			const initRes = await fetch("/api/bin", {
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

		setIsSubmitting(true);
		try {
			const res = await fetch("/api/bin", {
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

	return (
		<form onSubmit={handleSubmit} className="space-y-2">
			<Textarea
				value={content}
				onChange={(e) => setContent(e.target.value)}
				onPaste={handlePaste}
				placeholder="Paste something..."
				rows={3}
			/>
			<div className="flex items-center gap-3">
				<Button
					disabled={isSubmitting}
					type="submit"
					className="inline-flex items-center justify-center rounded-xl bg-gradient-to-r from-accent-primary to-accent-secondary px-6 py-3 text-base font-semibold text-white shadow-lg shadow-accent-primary/30 transition-transform duration-200 hover:scale-[1.02] hover:shadow-xl focus:outline-none focus-visible:ring-2 focus-visible:ring-white/60"
				>
					{isSubmitting ? "Adding..." : "Add"}
				</Button>
				{error ? <span className="text-sm text-red-600">{error}</span> : null}
			</div>
		</form>
	);
}
