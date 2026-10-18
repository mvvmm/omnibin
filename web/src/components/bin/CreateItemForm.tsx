"use client";

import { useRef, useState, useTransition } from "react";
import { initFileUpload } from "@/actions/initFileUpload";
import { uploadText as uploadTextAction } from "@/actions/uploadText";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { BIN_ITEMS_LIMIT } from "@/constants/constants";

export function CreateItemForm({ numItems }: { numItems: number }) {
  const [content, setContent] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isDragOver, setIsDragOver] = useState(false);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const [isPending, startTransition] = useTransition();

  async function uploadPastedFile(file: File) {
    setError(null);

    // For images only: Extract image dimensions on client
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

    startTransition(async () => {
      // Step 1: Get a signed upload URL (metadata only, no file data)
      const initResult = await initFileUpload({
        originalName: file.name || "pasted-file",
        contentType: file.type || "application/octet-stream",
        size: file.size,
        imageWidth,
        imageHeight,
      });

      if (!initResult.success) {
        setError(initResult.error || "Failed to init upload");
        return;
      }

      // Step 2: Upload file to storage
      const putRes = await fetch(initResult.uploadUrl, {
        method: "PUT",
        headers: {
          "Content-Type": file.type || "application/octet-stream",
        },
        body: file,
      });

      if (putRes.ok) window.dispatchEvent(new Event("bin:refresh"));
      if (!putRes.ok) {
        setError(`Failed to upload to storage (${putRes.status})`);
        return;
      }
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
      window.dispatchEvent(new Event("bin:refresh"));
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
      <div
        className={`flex items-end gap-2 rounded-lg border bg-card py-1.5 pr-1.5 pl-3.5 transition-[border-color,box-shadow] focus-within:border-ring focus-within:ring-[3px] focus-within:ring-ring/25 ${
          isDragOver ? "border-ring ring-[3px] ring-ring/25" : "border-input"
        }`}
      >
        <label htmlFor="bin-input" className="sr-only">
          Add to bin
        </label>
        <Textarea
          id="bin-input"
          ref={textareaRef}
          value={content}
          onChange={(e) => setContent(e.target.value)}
          onPaste={handlePaste}
          onDragOver={handleDragOver}
          onDragEnter={handleDragEnter}
          onDragLeave={handleDragLeave}
          onDrop={handleDrop}
          placeholder={
            isDragOver ? "Drop files here…" : "Paste or drop anything…"
          }
          rows={1}
          className="min-h-0 resize-none rounded-none border-0 bg-transparent px-0 py-[7px] text-[15px] leading-[22px] shadow-none focus-visible:ring-0 md:text-[15px] dark:bg-transparent"
        />
        <Button disabled={isPending} type="submit" className="h-9 px-4">
          {isPending ? "Adding…" : "Add"}
        </Button>
      </div>

      <div className="flex items-start justify-between gap-4 px-0.5 text-xs">
        <div className="text-destructive">
          {error ??
            (numItems >= BIN_ITEMS_LIMIT &&
              "Oldest item will be deleted on next add.")}
        </div>
        <div
          className={`font-mono text-[11px] ${numItems >= BIN_ITEMS_LIMIT ? "text-destructive" : "text-faint"}`}
        >
          {numItems} / {BIN_ITEMS_LIMIT}
        </div>
      </div>
    </form>
  );
}
