"use client";

import { deleteBinItem } from "@/actions/deleteBinItem";
import { getFileItemDownloadUrl } from "@/actions/getFileItemDownloadUrl";
import type { BinItem } from "@/types/bin";
import type { OgData } from "@/types/og";
import { formatFileSize } from "@/utils/formatFileSize";
import { isCopyableFile } from "@/utils/isCopyableFile";
import { extractFirstUrl, isUrl } from "@/utils/isUrl";
import {
  Check,
  Copy,
  Download,
  ExternalLink,
  Loader2,
  Trash2,
} from "lucide-react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useRef, useState, useTransition } from "react";
import { Button } from "../ui/button";
import { Card } from "../ui/card";
import { Skeleton } from "../ui/skeleton";
import { Tooltip, TooltipContent, TooltipTrigger } from "../ui/tooltip";

export function BinListItem({ item }: { item: BinItem }) {
  const router = useRouter();

  const [error, setError] = useState<string | null>(null);
  const [copied, setCopied] = useState<boolean | null>(null);
  const [downloaded, setDownloaded] = useState<boolean | null>(null);
  const [imageLoading, setImageLoading] = useState<boolean>(true);
  const [imageError, setImageError] = useState<boolean>(false);
  const [isAboveFold, setIsAboveFold] = useState<boolean>(false);

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
  const ogError = itemUrl && item.textItem?.ogDataFetched && !ogData;

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

  // Fetch helper: try preview URL first, fallback to a fresh presigned URL
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
        // ignore and fallback to fresh presigned URL
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

  if (deleteIsTransitioning) {
    return null;
  }

  const renderTitle = () => {
    if (item.kind === "TEXT" && item.textItem) {
      if (ogLoading) {
        return <Skeleton className="h-5 w-3/4" />;
      }
      if (ogData) {
        return ogData.title || new URL(ogData.url).hostname;
      }
      return item.textItem.content;
    }
    if (item.kind === "FILE" && item.fileItem) {
      return item.fileItem.originalName;
    }
    return "";
  };

  return (
    <li key={item.id}>
      <Card
        className="w-full p-3 text-foreground hover:scale-[101%] hover:cursor-pointer transition-transform !gap-0 glass"
        onClick={() => {
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
                item.fileItem?.originalName,
                item.fileItem?.preview ?? undefined
              );
            }
          }
        }}
        onKeyDown={(e) => {
          if (e.key === "Enter" || e.key === " ") {
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
                  item.fileItem?.originalName,
                  item.fileItem?.preview ?? undefined
                );
              }
            }
          }
        }}
      >
        <div className="flex items-start justify-between gap-3">
          <div
            className={`font-medium text-foreground flex-1 min-w-0 ${
              item.kind === "TEXT" ? "line-clamp-5" : "truncate"
            }`}
          >
            {renderTitle()}
          </div>
          <div className="flex items-center gap-1.5">
            {/* Copy Text Button */}
            {item.kind === "TEXT" && item.textItem && (
              <>
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
                {itemUrl && (
                  <Button
                    variant="ghost"
                    size="icon"
                    className="text-muted-foreground hover:text-primary hover:bg-primary/10"
                    aria-label="Open link in new tab"
                    title="Open in new tab"
                    onClick={(e) => {
                      e.stopPropagation();
                      window.open(itemUrl, "_blank", "noopener,noreferrer");
                    }}
                  >
                    <ExternalLink className="h-4 w-4" />
                  </Button>
                )}
              </>
            )}

            {/* Copy File Button */}
            {item.kind === "FILE" &&
              item.fileItem &&
              isCopyableFile(item.fileItem.contentType) && (
                <div className="relative">
                  <Tooltip>
                    <TooltipTrigger asChild>
                      <Button
                        variant="ghost"
                        size="icon"
                        className={`${
                          item.fileItem.contentType.startsWith("image/") &&
                          !item.fileItem.contentType.includes("png")
                            ? "text-amber-600 hover:bg-amber-500/10 hover:text-amber-500 dark:hover:text-amber-700"
                            : "text-muted-foreground hover:text-primary hover:bg-primary/10"
                        }`}
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
                          <Loader2 className="h-4 w-4 animate-spin" />
                        ) : copied ? (
                          <Check className="h-4 w-4 text-emerald-600" />
                        ) : (
                          <Copy className="h-4 w-4" />
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
                </div>
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
                    item?.fileItem?.preview ?? undefined
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
            {/* URL Open Graph Preview */}
            {item.kind === "TEXT" && (ogData || ogLoading) && (
              <div
                className={`block mt-2 -mx-3 overflow-hidden ${
                  ogData && !ogData?.image ? "border-t border-b mb-4" : ""
                }`}
                style={{
                  borderColor:
                    ogData && !ogData?.image ? "var(--border)" : undefined,
                }}
              >
                <div className="relative w-full overflow-hidden">
                  {/* Loading state */}
                  {ogLoading && (
                    <div
                      className="relative w-full overflow-hidden bg-muted/20"
                      style={{ aspectRatio: "16 / 9" }}
                    >
                      <Skeleton className="h-full w-full rounded-none dark:hidden" />
                    </div>
                  )}

                  {/* Error state */}
                  {ogError && !ogLoading && (
                    <div className="p-3 flex items-center gap-3">
                      <div className="w-5 h-5 text-muted-foreground">
                        <svg
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <title>Warning icon</title>
                          <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            strokeWidth={2}
                            d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"
                          />
                        </svg>
                      </div>
                      <div className="text-sm text-muted-foreground">
                        Preview unavailable
                      </div>
                    </div>
                  )}

                  {/* OG data content */}
                  {ogData && !ogLoading && !ogError && (
                    <>
                      {/* When rendering the OG image container: */}
                      {ogData?.image ? (
                        <div
                          ref={(el) => {
                            ogImageRef.current = el;
                            checkAboveFoldSync(el);
                          }}
                          className="relative w-full overflow-hidden bg-muted/20"
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
                      ) : (
                        <div className="p-3 flex items-center gap-3">
                          {ogLoading ? (
                            <>
                              <Skeleton className="w-5 h-5 rounded" />
                              <div className="min-w-0 flex-1">
                                <Skeleton className="h-4 w-3/4 mb-2" />
                                <Skeleton className="h-3 w-full mb-1" />
                                <Skeleton className="h-3 w-1/2" />
                              </div>
                            </>
                          ) : (
                            <>
                              {ogData.icon && (
                                <Image
                                  src={ogData.icon}
                                  alt="site icon"
                                  width={20}
                                  height={20}
                                  className="rounded"
                                  unoptimized
                                  referrerPolicy="no-referrer"
                                />
                              )}
                              <div className="min-w-0">
                                <div className="text-sm font-medium truncate">
                                  {ogData.title || new URL(ogData.url).hostname}
                                </div>
                                <div className="mt-1 text-xs text-muted-foreground truncate">
                                  {itemUrl}
                                </div>
                              </div>
                            </>
                          )}
                        </div>
                      )}
                    </>
                  )}

                  {/* Details block (title/desc/site) - show when loading or when there's an image */}
                  {(ogLoading || ogData?.image) && (
                    <div className="p-3">
                      {ogLoading ? (
                        <>
                          <Skeleton className="h-4 w-3/4 mb-2" />
                          <Skeleton className="h-3 w-[150px]" />
                        </>
                      ) : (
                        <>
                          <div className="text-sm font-medium truncate">
                            {ogData?.title ||
                              new URL(ogData?.url || "").hostname}
                          </div>
                          <div className="mt-1 text-xs text-muted-foreground truncate">
                            {itemUrl}
                          </div>
                        </>
                      )}
                    </div>
                  )}
                </div>
              </div>
            )}

            {item.kind === "FILE" &&
              item.fileItem &&
              item.fileItem.contentType.startsWith("image/") && (
                <div className="mb-4 mt-2 -mx-3">
                  {item.fileItem.preview && (
                    <div
                      ref={(el) => {
                        fileImageRef.current = el;
                        checkAboveFoldSync(el);
                      }}
                      className="h-[300px] w-full overflow-hidden bg-muted/30 relative"
                    >
                      {imageLoading && (
                        <div className="absolute inset-0 flex items-center justify-center">
                          <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
                        </div>
                      )}
                      {imageError && (
                        <div className="absolute inset-0 flex flex-col items-center justify-center text-muted-foreground">
                          <svg
                            className="h-6 w-6 mb-1"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                          >
                            <title>Image preview unavailable</title>
                            <path
                              strokeLinecap="round"
                              strokeLinejoin="round"
                              strokeWidth={2}
                              d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                            />
                          </svg>
                          <span className="text-xs">Preview unavailable</span>
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
      </Card>
    </li>
  );
}
