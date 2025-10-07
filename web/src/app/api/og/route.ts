import { NextResponse } from "next/server";
import { verifyAccessToken } from "@/lib/verifyAccessToken";

type OgResult = {
	title?: string | null;
	description?: string | null;
	image?: string | null;
	icon?: string | null;
	siteName?: string | null;
};

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
		// Very small, tolerant meta parsing without DOM dependencies
		const metaTagRegex = /<meta\s+[^>]*>/gi;
		const linkTagRegex = /<link\s+[^>]*>/gi;
		// Helper to grab attribute values regardless of quoting style
		const getAttr = (tag: string, name: string): string | null => {
			const regex = new RegExp(
				`(?:^|\\s)${name}\\s*=\\s*(?:"([^"]*)"|'([^']*)'|([^\\s>]+))`,
				"i",
			);
			const m = tag.match(regex);
			if (!m) return null;
			return m[1] ?? m[2] ?? m[3] ?? null;
		};
		const og: OgResult = {};

		// Collect image candidates to choose the best one (like iMessage)
		const imageCandidates: Array<{
			url: string;
			width?: number;
			height?: number;
			source: "og" | "twitter";
		}> = [];
		let lastOgImageIndex: number | null = null;
		let twitterCard: string | null = null;

		const tags = html.match(metaTagRegex) ?? [];
		for (const tag of tags) {
			const propRaw = getAttr(tag, "property") ?? getAttr(tag, "name");
			const contentRaw = getAttr(tag, "content");
			if (!propRaw || contentRaw == null) continue;
			const decodeEntities = (s: string): string => {
				// Minimal entity decoding for common cases (quotes, ampersand, lt/gt)
				return s
					.replace(/&quot;/g, '"')
					.replace(/&#34;/g, '"')
					.replace(/&apos;/g, "'")
					.replace(/&#39;/g, "'")
					.replace(/&amp;/g, "&")
					.replace(/&lt;/g, "<")
					.replace(/&gt;/g, ">");
			};
			const key = propRaw.toLowerCase();
			const value = decodeEntities(contentRaw);
			if (key === "og:title" || key === "twitter:title")
				og.title = og.title ?? value;
			if (key === "og:description" || key === "twitter:description")
				og.description = og.description ?? value;
			if (key === "twitter:card") twitterCard = value.toLowerCase();
			if (
				key === "og:image" ||
				key === "og:image:url" ||
				key === "og:image:secure_url"
			) {
				imageCandidates.push({ url: value, source: "og" });
				lastOgImageIndex = imageCandidates.length - 1;
			}
			if (key === "og:image:width" && lastOgImageIndex != null) {
				const n = Number.parseInt(value, 10);
				if (!Number.isNaN(n)) imageCandidates[lastOgImageIndex].width = n;
			}
			if (key === "og:image:height" && lastOgImageIndex != null) {
				const n = Number.parseInt(value, 10);
				if (!Number.isNaN(n)) imageCandidates[lastOgImageIndex].height = n;
			}
			if (key === "twitter:image" || key === "twitter:image:src") {
				imageCandidates.push({ url: value, source: "twitter" });
			}
			if (key === "og:site_name") og.siteName = og.siteName ?? value;
			if (key === "twitter:site") og.siteName = og.siteName ?? value;
		}

		// Fallbacks for title/icon
		if (!og.title) {
			const titleMatch = html.match(/<title[^>]*>([^<]*)<\/title>/i);
			if (titleMatch) og.title = titleMatch[1];
		}
		// Gather link icons and apple-touch-icons, pick the largest
		const linkTags = html.match(linkTagRegex) ?? [];
		let bestIconHref: string | null = null;
		let bestIconSize = 0; // area in px
		for (const tag of linkTags) {
			const relRaw = getAttr(tag, "rel");
			if (!relRaw) continue;
			const relValue = relRaw.toLowerCase();
			if (!/(icon|apple-touch-icon)/.test(relValue)) continue;
			const hrefVal = getAttr(tag, "href");
			if (!hrefVal) continue;
			const sizesRaw = getAttr(tag, "sizes");
			let sizeScore = 0;
			if (sizesRaw) {
				// e.g., "180x180" or multiple like "16x16 32x32"
				const parts = sizesRaw.split(/\s+/).map((s) =>
					s
						.toLowerCase()
						.split("x")
						.map((n) => Number(n)),
				);
				for (const p of parts) {
					if (p.length === 2 && !Number.isNaN(p[0]) && !Number.isNaN(p[1])) {
						sizeScore = Math.max(sizeScore, p[0] * p[1]);
					}
				}
			}
			// Prefer apple-touch-icon if sizes are equal
			if (
				sizeScore > bestIconSize ||
				(sizeScore === bestIconSize && relValue.includes("apple-touch-icon"))
			) {
				bestIconSize = sizeScore;
				bestIconHref = hrefVal;
			}
		}
		if (bestIconHref && !og.icon) og.icon = bestIconHref;

		// Pick best image candidate (prefer largest dimensions; prefer twitter when card is large)
		if (imageCandidates.length > 0) {
			const scored = imageCandidates
				.filter(
					(c) => c.url && !/(favicon|sprite|logo|icon\.svg|\.ico)/i.test(c.url),
				)
				.map((c) => {
					const area = (c.width ?? 0) * (c.height ?? 0);
					const twitterBoost =
						c.source === "twitter" &&
						(twitterCard?.includes("summary_large_image") ?? false)
							? 1.5
							: 1;
					const base = area > 0 ? area : 1;
					return { ...c, score: base * twitterBoost };
				});
			const best = scored.sort((a, b) => b.score - a.score)[0];
			if (best) og.image = best.url;
		}

		// No fallback to non-OG/Twitter images. If no candidate, leave og.image undefined/null.

		// Absolutize image/icon URLs
		og.image = og.image ? absolutizeUrl(og.image, safeUrl) : null;
		og.icon = og.icon ? absolutizeUrl(og.icon, safeUrl) : null;

		return NextResponse.json({ og });
	} catch (error) {
		const typed = error as Error & { statusCode?: number };
		return NextResponse.json(
			{ error: typed.message },
			{ status: typed.statusCode ?? 500 },
		);
	}
}
