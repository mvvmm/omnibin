import { load } from "cheerio";

// eslint-disable-next-line @typescript-eslint/no-var-requires
const he: { decode: (s: string) => string } = require("he");

import { NextResponse } from "next/server";
import { verifyAccessToken } from "@/lib/verifyAccessToken";
import type { OgData } from "@/types/og";

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

		// Fetch HTML (no cookies, no credentials)
		const res = await fetch(safeUrl, {
			method: "GET",
			headers: {
				// Prefer HTML
				accept:
					"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
				"user-agent":
					"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
			},
			redirect: "follow",
			cache: "no-store",
		});
		if (!res.ok) {
			return NextResponse.json(
				{ error: `Failed to fetch URL (${res.status})` },
				{ status: 400 },
			);
		}

		const html = await res.text();
		const $ = load(html);
		const og: OgData = { url: safeUrl } as OgData;

		const pick = (selectors: string[]): string | undefined => {
			for (const s of selectors) {
				const val = $(s).attr("content");
				if (val) return he.decode(val);
			}
			return undefined;
		};
		og.title =
			pick([
				'meta[property="og:title"]',
				'meta[name="og:title"]',
				'meta[name="twitter:title"]',
			]) ?? he.decode($("title").first().text() || "");
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
			'meta[property="og:image:width"], meta[name="og:image:width"]',
		).attr("content");
		const h = $(
			'meta[property="og:image:height"], meta[name="og:image:height"]',
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

		// Fallbacks for title/icon
		if (!og.title) {
			const titleMatch = html.match(/<title[^>]*>([^<]*)<\/title>/i);
			if (titleMatch) {
				const dec = (s: string) =>
					s
						.replace(/&quot;/g, '"')
						.replace(/&apos;/g, "'")
						.replace(/&amp;/g, "&")
						.replace(/&lt;/g, "<")
						.replace(/&gt;/g, ">")
						.replace(/&#(\d+);/g, (_, d: string) =>
							String.fromCodePoint(Number.parseInt(d, 10) || 0),
						)
						.replace(/&#x([0-9a-fA-F]+);/g, (_, h: string) =>
							String.fromCodePoint(Number.parseInt(h, 16) || 0),
						);
				og.title = dec(titleMatch[1]);
			}
		}

		// No fallback to non-OG/Twitter images. If no candidate, leave og.image undefined/null.

		// Provider-specific fallbacks (production-safe)
		try {
			const u = new URL(safeUrl);
			const host = u.hostname.toLowerCase();
			const isYouTube =
				host.includes("youtube.com") ||
				host === "youtu.be" ||
				host.endsWith(".youtu.be");
			if (isYouTube && (!og.title || !og.image)) {
				const oembed = new URL("https://www.youtube.com/oembed");
				oembed.searchParams.set("url", safeUrl);
				oembed.searchParams.set("format", "json");
				const oeRes = await fetch(oembed.toString(), {
					method: "GET",
					cache: "no-store",
					headers: { "accept-language": "en" },
					redirect: "follow",
				});
				if (oeRes.ok) {
					const data = (await oeRes.json()) as {
						title?: string;
						thumbnail_url?: string;
					};
					og.title = og.title ?? (data.title ? he.decode(data.title) : null);
					og.image = og.image ?? data.thumbnail_url ?? null;
					og.siteName = og.siteName ?? "YouTube";
				}
			}
		} catch {
			// ignore
		}

		// Absolutize image/icon URLs
		og.image = og.image ? absolutizeUrl(og.image, safeUrl) : null;
		og.icon = og.icon ? absolutizeUrl(og.icon, safeUrl) : null;

		// Favicon fallback: if no icon tag was present, try /favicon.ico
		if (!og.icon) {
			const fallbackFavicon = absolutizeUrl("/favicon.ico", safeUrl);
			if (fallbackFavicon) {
				try {
					// Prefer HEAD; some servers don't support it, so fall back to GET
					let headOk = false;
					try {
						const headRes = await fetch(fallbackFavicon, {
							method: "HEAD",
							cache: "no-store",
							redirect: "follow",
						});
						headOk =
							headRes.ok &&
							(headRes.headers.get("content-type") ?? "").includes("image");
					} catch {
						/* ignore */
					}
					if (!headOk) {
						const getRes = await fetch(fallbackFavicon, {
							method: "GET",
							cache: "no-store",
							redirect: "follow",
						});
						if (
							getRes.ok &&
							(getRes.headers.get("content-type") ?? "").includes("image")
						) {
							og.icon = fallbackFavicon;
						}
					} else {
						og.icon = fallbackFavicon;
					}
				} catch {
					/* ignore */
				}
			}
		}

		return NextResponse.json({ og });
	} catch (error) {
		const typed = error as Error & { statusCode?: number };
		return NextResponse.json(
			{ error: typed.message },
			{ status: typed.statusCode ?? 500 },
		);
	}
}
