"use client";

import { deleteBinItem } from "@/actions/deleteBinItem";
import { getFileItemDownloadUrl } from "@/actions/getFileItemDownloadUrl";
import type { BinItem } from "@/types/bin";
import type { OgData } from "@/types/og";
import { isCopyableFile } from "@/utils/isCopyableFile";
import { extractFirstUrl, isUrl } from "@/utils/isUrl";
import {
  Check,
  Copy,
  Download,
  ExternalLink,
  FileIcon,
  Loader2,
  Trash2,
} from "lucide-react";
import Image from "@/components/image";

import { useEffect, useMemo, useRef, useState, useTransition } from "react";
import { Button } from "../ui/button";
import { Skeleton } from "../ui/skeleton";
import { Tooltip, TooltipContent, TooltipTrigger } from "../ui/tooltip";

export function BinListItem({ item }: { item: BinItem }) {
  const [error, setError] = useState<string | null>(null);
  const [copied, setCopied] = useState<boolean | null>(null);
  const [downloaded, setDownloaded] = useState<boolean | null>(null);
  const [imageLoading, setImageLoading] = useState<boolean>(true);
  const [imageError, setImageError] = useState<boolean>(false);
  const [isAboveFold, setIsAboveFold] = useState<boolean>(false);
  const [deleted, setDeleted] = useState<boolean>(false);

  // Ref callback to check if element is above fold synchronously when mounted
  const checkAboveFoldSync = (element: HTMLDivElement | null) => {
    if (!element) return;

    const rect = element.getBoundingClientRect();
    const viewportHeight = window.innerHeight;
    // Consider it above fold if it's within the viewport or 200px above it
    if (rect.top < viewportHeight + 200) {
      setIsAboveFold(true);
    }
  };

  const ogImageRef = useRef<HTMLDivElement>(null);
  const fileImageRef = useRef<HTMLDivElement>(null);

  // Extract and validate URL once
  const itemUrl = useMemo(() => {
    if (item.kind !== "TEXT" || !item.textItem?.content) {
      return null;
    }
    const url = extractFirstUrl(item.textItem.content);
    return url && isUrl(url) ? url : null;
  }, [item.kind, item.textItem?.content]);

  // Convert stored OG data to OgData format
  const ogData = useMemo((): OgData | null => {
    if (!item.textItem || !itemUrl) return null;
    if (!item.textItem.ogDataFetched) return null;

    // If fetched but all fields are null, return null (no OG data available)
    if (
      !item.textItem.ogTitle &&
      !item.textItem.ogDescription &&
      !item.textItem.ogImage &&
      !item.textItem.ogIcon &&
      !item.textItem.ogSiteName
    ) {
      return null;
    }

    return {
      url: itemUrl,
      title: item.textItem.ogTitle,
      description: item.textItem.ogDescription,
      image: item.textItem.ogImage,
      imageWidth: item.textItem.ogImageWidth,
      imageHeight: item.textItem.ogImageHeight,
      icon: item.textItem.ogIcon,
      siteName: item.textItem.ogSiteName,
    };
  }, [item.textItem, itemUrl]);

  const ogLoading = itemUrl && !item.textItem?.ogDataFetched;

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

  // Detect if images are above the fold using Intersection Observer
  const hasFileImagePreview = item.kind === "FILE" && !!item.fileItem?.preview;
  const ogImageUrl = ogData?.image ?? null;
  useEffect(() => {
    const refs = [ogImageRef.current, fileImageRef.current].filter(
      Boolean
    ) as HTMLElement[];

    if (refs.length === 0) return;

    // Use Intersection Observer for accurate detection
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting && entry.intersectionRatio > 0) {
            setIsAboveFold(true);
            // Once we detect it's above fold, we can disconnect
            observer.disconnect();
          }
        });
      },
      {
        // Check immediately if element is in viewport
        rootMargin: "200px", // Consider 200px above viewport as "above fold"
        threshold: 0,
      }
    );

    refs.forEach((ref) => observer.observe(ref));

    return () => {
      observer.disconnect();
    };
  }, [ogImageUrl, hasFileImagePreview]);

  const handleDelete = async (id: string) => {
    startDeleteTransition(async () => {
      try {
        setError(null);
        const { success, error } = await deleteBinItem(id);

        if (success) {
          setDeleted(true);
          window.dispatchEvent(new Event("bin:refresh"));
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
    existingUrl?: string
  ) => {
    startDownloadTransition(async () => {
      try {
        setError(null);
        const res = await fetchFileResponse(id, existingUrl);
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
    existingUrl?: string
  ) => {
    startCopyingTransition(async () => {
      try {
        setError(null);
        const res = await fetchFileResponse(id, existingUrl);
        const blob = await res.blob();
        const mime =
          blob.type || expectedContentType || "application/octet-stream";

        // Try different approaches for copying to clipboard
        try {
          // First, try with the original MIME type
          await navigator.clipboard.write([
            new ClipboardItem({ [mime]: blob }),
          ]);
          setCopied(true);
        } catch (clipboardError) {
          console.log(
            "Original MIME type failed, trying fallbacks:",
            clipboardError
          );

          // If it's an image, we need to convert to PNG for clipboard compatibility
          if (mime.startsWith("image/")) {
            try {
              // Convert image to PNG format for clipboard compatibility
              const canvas = document.createElement("canvas");
              const ctx = canvas.getContext("2d");
              const img = new window.Image();

              await new Promise<void>((resolve, reject) => {
                img.onload = () => {
                  canvas.width = img.width;
                  canvas.height = img.height;
                  ctx?.drawImage(img, 0, 0);

                  // Convert to PNG for clipboard (browsers typically only support PNG in clipboard)
                  canvas.toBlob(
                    (pngBlob) => {
                      if (pngBlob) {
                        navigator.clipboard
                          .write([new ClipboardItem({ "image/png": pngBlob })])
                          .then(() => {
                            setCopied(true);
                            resolve();
                          })
                          .catch(reject);
                      } else {
                        reject(new Error("Failed to convert image to PNG"));
                      }
                    },
                    "image/png",
                    0.8
                  );
                };
                img.onerror = reject;
                img.src = URL.createObjectURL(blob);
              });
            } catch (conversionError) {
              throw new Error(
                `Failed to copy image to clipboard. This browser may not support image copying.`
              );
            }
          } else {
            // For non-image files, try with generic binary data
            try {
              await navigator.clipboard.write([
                new ClipboardItem({ "application/octet-stream": blob }),
              ]);
              setCopied(true);
            } catch {
              throw new Error(
                `Failed to copy file to clipboard. Original error: ${(clipboardError as Error).message}`
              );
            }
          }
        }
      } catch (err) {
        const error = err as Error;
        setError(error.message);
      }
    });
  };

  // Fetch helper: try preview URL first, fallback to a fresh signed URL
  const fetchFileResponse = async (
    id: string,
    existingUrl?: string
  ): Promise<Response> => {
    let res: Response | undefined;
    if (existingUrl) {
      try {
        const r = await fetch(existingUrl);
        if (r.ok) res = r;
      } catch {
        // ignore and fallback to fresh signed URL
      }
    }
    if (!res || !res.ok) {
      const { success, error, downloadUrl } = await getFileItemDownloadUrl(id);
      if (!success || !downloadUrl) {
        throw new Error(error || "Failed to get file URL");
      }
      res = await fetch(downloadUrl);
    }
    if (!res.ok) {
      throw new Error(`Fetch file failed (${res.status})`);
    }
    return res;
  };

  // Prefer the image's native aspect ratio, but clamp very tall/portrait images to 16:9 like iOS
  const aspect = (() => {
    const w = ogData?.imageWidth ?? null;
    const h = ogData?.imageHeight ?? null;
    if (w && h && w > 0 && h > 0) {
      const ratio = w / h; // width over height
      // If portrait or unusually tall (e.g., < 1.3), use 16:9 container to avoid huge vertical cards
      if (ratio < 1.3) return "16 / 9";
      return `${w} / ${h}`;
    }
    return "16 / 9";
  })();

  if (deleteIsTransitioning || deleted) {
    return null;
  }

  const handleActivate = () => {
    if (item.kind === "TEXT" && item.textItem) {
      handleCopyText(item.textItem.content);
    }
    if (item.kind === "FILE" && item.fileItem) {
      if (isCopyableFile(item.fileItem.contentType)) {
        handleCopyFile(
          item.id,
          item.fileItem.contentType,
          item.fileItem.preview ?? undefined
        );
      } else {
        handleDownloadFile(
          item.id,
          item.fileItem.originalName,
          item.fileItem.preview ?? undefined
        );
      }
    }
  };

  const iconButtonClassName =
    "size-10 text-muted-foreground hover:text-foreground";
  const isImageFile =
    item.kind === "FILE" && !!item.fileItem?.contentType.startsWith("image/");
  const showLinkPreview = item.kind === "TEXT" && (ogData || ogLoading);

  const renderMedia = () => {
    if (ogLoading) {
      return (
        <Skeleton
          className="w-full rounded-none"
          style={{ aspectRatio: "16 / 9" }}
        />
      );
    }
    if (item.kind === "TEXT" && ogData?.image) {
      return (
        <div
          ref={(el) => {
            ogImageRef.current = el;
            checkAboveFoldSync(el);
          }}
          className="relative w-full overflow-hidden bg-media"
          style={{ aspectRatio: aspect }}
        >
          <Image
            src={ogData.image}
            alt={ogData.title ?? "link preview"}
            fill
            className="object-cover"
            unoptimized
            referrerPolicy="no-referrer"
            loading={isAboveFold ? "eager" : "lazy"}
          />
        </div>
      );
    }
    if (isImageFile && item.fileItem?.preview) {
      return (
        <div
          ref={(el) => {
            fileImageRef.current = el;
            checkAboveFoldSync(el);
          }}
          className="relative aspect-video w-full overflow-hidden bg-media"
        >
          {imageLoading && (
            <div className="absolute inset-0 flex items-center justify-center">
              <Loader2 className="size-5 animate-spin text-muted-foreground" />
            </div>
          )}
          {imageError && (
            <div className="absolute inset-0 flex items-center justify-center text-xs text-muted-foreground">
              Preview unavailable
            </div>
          )}
          <Image
            src={item.fileItem.preview}
            alt={item.fileItem.originalName}
            width={item.fileItem.imageWidth ?? 320}
            height={item.fileItem.imageHeight ?? 240}
            className={`h-full w-full object-cover ${imageLoading ? "opacity-0" : "opacity-100"} transition-opacity duration-200`}
            quality={50}
            loading={isAboveFold ? "eager" : "lazy"}
            onLoad={() => setImageLoading(false)}
            onError={() => {
              setImageLoading(false);
              setImageError(true);
            }}
          />
        </div>
      );
    }
    return null;
  };

  const renderBody = () => {
    if (showLinkPreview) {
      if (ogLoading) {
        return (
          <div className="space-y-2 py-2">
            <Skeleton className="h-4 w-3/4" />
            <Skeleton className="h-3 w-24" />
          </div>
        );
      }
      if (ogData) {
        const hostname = new URL(ogData.url).hostname;
        return (
          <div className="flex min-w-0 flex-col gap-0.5 py-1.5">
            <span className="truncate">{ogData.title || hostname}</span>
            <span className="truncate text-[13px] text-muted-foreground">
              {hostname}
            </span>
          </div>
        );
      }
    }
    if (item.kind === "TEXT" && item.textItem) {
      return (
        <div className="line-clamp-5 py-2.5 leading-normal break-words whitespace-pre-wrap">
          {item.textItem.content}
        </div>
      );
    }
    if (item.kind === "FILE" && item.fileItem && !isImageFile) {
      return (
        <div className="flex min-w-0 items-center gap-3 py-2.5">
          <FileIcon className="size-[18px] shrink-0 text-muted-foreground" />
          <span className="truncate">{item.fileItem.originalName}</span>
        </div>
      );
    }
    return null;
  };

  return (
    <li key={item.id}>
      <div
        className="w-full cursor-pointer overflow-hidden rounded-lg border bg-card text-card-foreground transition-colors hover:border-input"
        onClick={handleActivate}
        onKeyDown={(e) => {
          if (e.key === "Enter" || e.key === " ") handleActivate();
        }}
      >
        <div
          className={`flex gap-2 py-1.5 pr-1.5 pl-4 ${item.kind === "TEXT" && !showLinkPreview ? "items-start" : "items-center"}`}
        >
          <div className="min-w-0 flex-1">{renderBody()}</div>
          <div className="flex shrink-0 items-center">
            {/* Copy Text Button */}
            {item.kind === "TEXT" && item.textItem && (
              <>
                <Button
                  variant="ghost"
                  size="icon"
                  className={iconButtonClassName}
                  aria-label="Copy to clipboard"
                  title="Copy"
                  disabled={copyIsTransitioning}
                  onClick={(e) => {
                    e.stopPropagation();
                    item.textItem && handleCopyText(item.textItem.content);
                  }}
                >
                  {copied ? <Check className="text-primary-ink" /> : <Copy />}
                </Button>
                {itemUrl && (
                  <Button
                    variant="ghost"
                    size="icon"
                    className={iconButtonClassName}
                    aria-label="Open link in new tab"
                    title="Open in new tab"
                    onClick={(e) => {
                      e.stopPropagation();
                      window.open(itemUrl, "_blank", "noopener,noreferrer");
                    }}
                  >
                    <ExternalLink />
                  </Button>
                )}
              </>
            )}

            {/* Copy File Button */}
            {item.kind === "FILE" &&
              item.fileItem &&
              isCopyableFile(item.fileItem.contentType) && (
                <Tooltip>
                  <TooltipTrigger asChild>
                    <Button
                      variant="ghost"
                      size="icon"
                      className={
                        item.fileItem.contentType.startsWith("image/") &&
                        !item.fileItem.contentType.includes("png")
                          ? "size-10 text-primary-ink hover:text-primary-ink"
                          : iconButtonClassName
                      }
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
                          item?.fileItem?.preview ?? undefined
                        );
                      }}
                    >
                      {copyIsTransitioning ? (
                        <Loader2 className="animate-spin" />
                      ) : copied ? (
                        <Check className="text-primary-ink" />
                      ) : (
                        <Copy />
                      )}
                    </Button>
                  </TooltipTrigger>
                  {item.fileItem.contentType.startsWith("image/") &&
                    !item.fileItem.contentType.includes("png") && (
                      <TooltipContent side="top" className="max-w-[300px]">
                        Image will be converted to .png on copy due to browser
                        limitations. This can cause much larger file sizes,
                        amongst other issues. Consider using download instead.
                      </TooltipContent>
                    )}
                </Tooltip>
              )}

            {/* Download File Button */}
            {item.kind === "FILE" && item.fileItem && (
              <Button
                variant="ghost"
                size="icon"
                className={iconButtonClassName}
                aria-label="Download file"
                title="Download"
                disabled={downloadIsTransitioning}
                onClick={(e) => {
                  e.stopPropagation();
                  handleDownloadFile(
                    item.id,
                    item.fileItem?.originalName,
                    item?.fileItem?.preview ?? undefined
                  );
                }}
              >
                {downloadIsTransitioning ? (
                  <Loader2 className="animate-spin" />
                ) : downloaded ? (
                  <Check className="text-primary-ink" />
                ) : (
                  <Download />
                )}
              </Button>
            )}

            {/* Delete Button */}
            <Button
              variant="ghost"
              size="icon"
              className="size-10 text-muted-foreground hover:text-destructive"
              aria-label="Delete item"
              title="Delete"
              onClick={(e) => {
                e.stopPropagation();
                handleDelete(item.id);
              }}
            >
              <Trash2 />
            </Button>
          </div>
        </div>

        {renderMedia()}

        {error && (
          <div className="px-4 py-2.5 text-xs text-destructive">{error}</div>
        )}
      </div>
    </li>
  );
}
