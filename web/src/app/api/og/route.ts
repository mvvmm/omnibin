import { load } from "cheerio";
import he from "he";

import { verifyAccessToken } from "@/lib/verifyAccessToken";
import type { OgData } from "@/types/og";
import { NextResponse } from "next/server";

function sanitizeUrl(input: string): string | null {
  try {
    const u = new URL(input);
    if (u.protocol !== "http:" && u.protocol !== "https:") return null;
    return u.toString();
  } catch {
    return null;
  }
}

function absolutizeUrl(possiblyRelative: string, base: string): string | null {
  try {
    const baseUrl = new URL(base);
    return new URL(possiblyRelative, baseUrl).toString();
  } catch {
    return null;
  }
}

export const runtime = "nodejs";

export async function POST(req: Request) {
  try {
    await verifyAccessToken(req.headers.get("authorization") ?? undefined);

    const body = (await req.json().catch(() => undefined)) as
      | { url?: string }
      | undefined;
    const inputUrl = body?.url ?? "";
    const safeUrl = sanitizeUrl(inputUrl);
    if (!safeUrl) {
      return NextResponse.json({ error: "Invalid URL" }, { status: 400 });
    }

    // Early platform detection - handle YouTube and Twitch specially
    try {
      const u = new URL(safeUrl);
      const host = u.hostname.toLowerCase();

      const isYouTube =
        host.includes("youtube.com") ||
        host === "youtu.be" ||
        host.endsWith(".youtu.be");

      const isTwitch = host === "www.twitch.tv" || host === "twitch.tv";

      if (isYouTube) {
        const oembed = new URL("https://www.youtube.com/oembed");
        oembed.searchParams.set("url", safeUrl);
        oembed.searchParams.set("format", "json");

        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 10000); // 10 second timeout

        try {
          const oeRes = await fetch(oembed.toString(), {
            method: "GET",
            cache: "force-cache",
            headers: { "accept-language": "en" },
            redirect: "follow",
            signal: controller.signal,
          });
          clearTimeout(timeoutId);

          if (oeRes.ok) {
            const data = (await oeRes.json()) as {
              title?: string;
              thumbnail_url?: string;
            };
            const og: OgData = {
              url: safeUrl,
              title: data.title ? he.decode(data.title) : null,
              image: data.thumbnail_url ?? null,
              siteName: "YouTube",
            };
            return NextResponse.json({ og });
          }
        } catch {
          clearTimeout(timeoutId);
          // Fall through to regular HTML parsing if oembed fails
        }
      }

      if (isTwitch) {
        const isTwitchClip = u.pathname.includes("/clip/");
        const isTwitchVod = u.pathname.includes("/videos/");
        const isTwitchStream =
          !isTwitchClip && !isTwitchVod && u.pathname !== "/";

        // Enhanced HTML parsing for Twitch content
        // Twitch often loads content dynamically, so we need a longer timeout
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 20000); // Longer timeout for Twitch

        try {
          const res = await fetch(safeUrl, {
            method: "GET",
            headers: {
              "User-Agent":
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
              Accept:
                "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
              "Accept-Language": "en-US,en;q=0.9",
              "Accept-Encoding": "gzip, deflate, br",
              "Cache-Control": "no-cache",
            },
            redirect: "follow",
            cache: "no-cache", // Don't cache Twitch content as it changes frequently
            signal: controller.signal,
          });
          clearTimeout(timeoutId);

          if (res.ok) {
            const html = await res.text();
            const $ = load(html);

            // Try to extract title from various sources with fallbacks
            let title =
              $('meta[property="og:title"]').attr("content") ||
              $('meta[name="twitter:title"]').attr("content") ||
              $("title").text() ||
              null;

            // Try to extract description
            const description =
              $('meta[property="og:description"]').attr("content") ||
              $('meta[name="twitter:description"]').attr("content") ||
              null;

            // Try to extract image with multiple fallbacks
            const image =
              $('meta[property="og:image"]').attr("content") ||
              $('meta[name="twitter:image"]').attr("content") ||
              $('meta[property="og:image:url"]').attr("content") ||
              $('meta[property="og:image:secure_url"]').attr("content") ||
              null;

            // For Twitch clips, try to construct a better title if missing
            if (isTwitchClip && !title) {
              // Try to extract streamer name from various meta tags
              const streamerName =
                $('meta[property="og:video:tag"]').attr("content") ||
                $('meta[name="twitter:label1"]').attr("content") ||
                $('meta[property="og:site_name"]').attr("content") ||
                $('meta[property="og:video:actor"]').attr("content");

              if (streamerName) {
                title = `Twitch Clip - ${streamerName}`;
              } else {
                // Try to extract from URL path as fallback
                const pathParts = u.pathname.split("/");
                const clipIndex = pathParts.indexOf("clip");
                if (clipIndex > 0 && pathParts[clipIndex - 1]) {
                  title = `Twitch Clip - ${pathParts[clipIndex - 1]}`;
                } else {
                  title = "Twitch Clip";
                }
              }
            }

            // For Twitch streams, try to get streamer name
            if (isTwitchStream && !title) {
              const streamerName = u.pathname.split("/")[1]; // Extract from URL path
              if (
                streamerName &&
                streamerName !== "directory" &&
                streamerName !== "videos"
              ) {
                title = `${streamerName} - Twitch Stream`;
              }
            }

            // For Twitch VODs, try to get video title
            if (isTwitchVod && !title) {
              const vodTitle =
                $('h1[data-a-target="video-title"]').text() ||
                $(".video-title").text() ||
                $("h1").first().text();
              if (vodTitle) {
                title = vodTitle;
              }
            }

            // If we got some data, return it
            if (title || image) {
              const og: OgData = {
                url: safeUrl,
                title: title ? he.decode(title) : null,
                description: description ? he.decode(description) : null,
                image: image ? absolutizeUrl(image, safeUrl) : null,
                siteName: "Twitch",
              };
              return NextResponse.json({ og });
            }
          }
        } catch {
          clearTimeout(timeoutId);
          // Fall through to regular HTML parsing if Twitch-specific handling fails
        }
      }
    } catch {
      // Fall through to regular HTML parsing if URL parsing fails
    }

    // Fetch HTML with range request and timeout
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 15000); // 15 second timeout

    const res = await fetch(safeUrl, {
      method: "GET",
      headers: {
        Range: "bytes=0-8192", // First 8KB should contain meta tags
        accept:
          "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "user-agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
      },
      redirect: "follow",
      cache: "force-cache",
      signal: controller.signal,
    });
    clearTimeout(timeoutId);
    if (!res.ok) {
      return NextResponse.json(
        { error: `Failed to fetch URL (${res.status})` },
        { status: 400 }
      );
    }

    let html = await res.text();
    let $ = load(html);

    // Check if we got a partial response (206) or full response (200)
    // If partial and no meta tags found, we might need the full page
    const isPartialResponse = res.status === 206;
    const hasMetaTags =
      $('meta[property^="og:"], meta[name^="twitter:"]').length > 0;

    // Fallback: if we got a partial response but no meta tags, fetch the full page
    if (isPartialResponse && !hasMetaTags) {
      const fallbackController = new AbortController();
      const fallbackTimeoutId = setTimeout(
        () => fallbackController.abort(),
        15000
      );

      try {
        const fullRes = await fetch(safeUrl, {
          method: "GET",
          headers: {
            accept:
              "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "user-agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
          },
          redirect: "follow",
          cache: "force-cache",
          signal: fallbackController.signal,
        });
        clearTimeout(fallbackTimeoutId);

        if (fullRes.ok) {
          html = await fullRes.text();
          $ = load(html);
        }
      } catch {
        clearTimeout(fallbackTimeoutId);
        // Continue with partial HTML if fallback fails
      }
    }

    const og: OgData = { url: safeUrl } as OgData;

    const pick = (selectors: string[]): string | undefined => {
      for (const s of selectors) {
        const val = $(s).attr("content");
        if (val) return he.decode(val);
      }
      return undefined;
    };
    og.title = pick([
      'meta[property="og:title"]',
      'meta[name="og:title"]',
      'meta[name="twitter:title"]',
    ]);
    og.description = pick([
      'meta[property="og:description"]',
      'meta[name="og:description"]',
      'meta[name="twitter:description"]',
    ]);

    const imageSelectors = [
      'meta[property="og:image"]',
      'meta[property="og:image:url"]',
      'meta[property="og:image:secure_url"]',
      'meta[name="twitter:image"]',
      'meta[name="twitter:image:src"]',
    ];
    for (const s of imageSelectors) {
      const v = $(s).attr("content");
      if (v) {
        og.image = v;
        break;
      }
    }

    // Try to read dimensions if present
    const w = $(
      'meta[property="og:image:width"], meta[name="og:image:width"]'
    ).attr("content");
    const h = $(
      'meta[property="og:image:height"], meta[name="og:image:height"]'
    ).attr("content");
    if (w && h) {
      const wi = Number.parseInt(w, 10);
      const hi = Number.parseInt(h, 10);
      if (!Number.isNaN(wi) && !Number.isNaN(hi)) {
        og.imageWidth = wi;
        og.imageHeight = hi;
      }
    }

    const iconCandidates = $('link[rel~="apple-touch-icon"], link[rel~="icon"]')
      .map((_, el) => $(el).attr("href") || "")
      .get()
      .filter(Boolean) as string[];
    if (!og.icon && iconCandidates.length > 0) {
      og.icon = iconCandidates[0];
    }

    // Absolutize image/icon URLs and upgrade http to https
    // Many sites (e.g. Shopify) serve og:image with http:// but support https.
    // iOS App Transport Security blocks plain http, causing AsyncImage to fail silently.
    og.image = og.image ? absolutizeUrl(og.image, safeUrl)?.replace(/^http:\/\//, "https://") ?? null : null;
    og.icon = og.icon ? absolutizeUrl(og.icon, safeUrl)?.replace(/^http:\/\//, "https://") ?? null : null;

    return NextResponse.json({ og });
  } catch (error) {
    const typed = error as Error & { statusCode?: number };
    return NextResponse.json(
      { error: typed.message },
      { status: typed.statusCode ?? 500 }
    );
  }
}
