import { NextResponse } from "next/server";
import {
  BIN_ITEMS_LIMIT,
  MAX_CHAR_LIMIT,
  MAX_FILE_SIZE,
} from "@/constants/constants";
import { prisma } from "@/lib/prisma";
import {
  createPresignedPutUrl,
  deleteObjectByKey,
  getBucketName,
} from "@/lib/s3";
import { serializeForJson } from "@/lib/utils";
import { verifyAccessToken } from "@/lib/verifyAccessToken";
import type { OgData } from "@/types/og";
import { extractFirstUrl, isUrl } from "@/utils/isUrl";

export async function GET(req: Request) {
  try {
    const payload = await verifyAccessToken(
      req.headers.get("authorization") ?? undefined
    );
    const auth0Sub = payload.sub;
    const authHeader = req.headers.get("authorization");

    // Ensure user exists and fetch their bin items (clipboard entries)
    const user = await prisma.user.upsert({
      where: { auth0Id: auth0Sub },
      update: {},
      create: { auth0Id: auth0Sub },
      select: { id: true },
    });

    const items = await prisma.binItem.findMany({
      where: { userId: user.id },
      orderBy: { createdAt: "desc" },
      take: 100,
      include: { textItem: true, fileItem: true },
    });

    // Fetch OG data for URL items that haven't been fetched yet
    const ogFetchPromises = items
      .filter((item) => {
        if (item.kind !== "TEXT" || !item.textItem) return false;
        if (item.textItem.ogDataFetched) return false;
        const url = extractFirstUrl(item.textItem.content);
        return url && isUrl(url);
      })
      .map(async (item) => {
        if (!item.textItem) return;
        const url = extractFirstUrl(item.textItem.content);
        if (!url) return;

        try {
          // Call the OG API endpoint internally
          const ogEndpoint = new URL(
            "/api/og",
            process.env.NEXT_PUBLIC_BASE_URL ||
              `http://localhost:${process.env.PORT || 3000}`
          );
          const ogRes = await fetch(ogEndpoint, {
            method: "POST",
            headers: {
              Authorization: authHeader || "",
              "Content-Type": "application/json",
            },
            body: JSON.stringify({ url }),
          });

          if (ogRes.ok) {
            const ogResult = (await ogRes.json()) as { og?: OgData };
            const og = ogResult.og;

            // Update the text item with OG data
            await prisma.textItem.update({
              where: { id: item.textItem.id },
              data: {
                ogDataFetched: true,
                ogTitle: og?.title ?? null,
                ogDescription: og?.description ?? null,
                ogImage: og?.image ?? null,
                ogImageWidth: og?.imageWidth ?? null,
                ogImageHeight: og?.imageHeight ?? null,
                ogIcon: og?.icon ?? null,
                ogSiteName: og?.siteName ?? null,
              },
            });

            // Update the in-memory item so the response includes the OG data
            item.textItem.ogDataFetched = true;
            item.textItem.ogTitle = og?.title ?? null;
            item.textItem.ogDescription = og?.description ?? null;
            item.textItem.ogImage = og?.image ?? null;
            item.textItem.ogImageWidth = og?.imageWidth ?? null;
            item.textItem.ogImageHeight = og?.imageHeight ?? null;
            item.textItem.ogIcon = og?.icon ?? null;
            item.textItem.ogSiteName = og?.siteName ?? null;
          } else {
            // Mark as fetched even if it failed, so we don't keep retrying
            await prisma.textItem.update({
              where: { id: item.textItem.id },
              data: { ogDataFetched: true },
            });
            item.textItem.ogDataFetched = true;
          }
        } catch (error) {
          console.error("Error fetching OG data for URL:", url, error);
          // Mark as fetched even on error, so we don't keep retrying
          await prisma.textItem.update({
            where: { id: item.textItem.id },
            data: { ogDataFetched: true },
          });
          item.textItem.ogDataFetched = true;
        }
      });

    // Wait for all OG fetches to complete
    await Promise.all(ogFetchPromises);

    return NextResponse.json(serializeForJson({ items }));
  } catch (error) {
    const typed = error as Error & { statusCode?: number };
    console.error(
      "Error in GET /api/bin:",
      typed.message,
      "Status:",
      typed.statusCode ?? 401
    );
    return NextResponse.json(
      { error: typed.message },
      { status: typed.statusCode ?? 401 }
    );
  }
}

export async function POST(req: Request) {
  try {
    const payload = await verifyAccessToken(
      req.headers.get("authorization") ?? undefined
    );
    const auth0Sub = payload.sub;
    const authHeader = req.headers.get("authorization");

    const body = (await req.json().catch(() => undefined)) as
      | {
          content?: string;
          file?: {
            originalName: string;
            contentType: string;
            size: number;
            imageWidth?: number | null;
            imageHeight?: number | null;
          };
        }
      | undefined;

    // Ensure user exists
    const user = await prisma.user.upsert({
      where: { auth0Id: auth0Sub },
      update: {},
      create: { auth0Id: auth0Sub },
      select: { id: true },
    });

    // Check if adding this item would exceed the limit and delete oldest if necessary
    const currentItemCount = await prisma.binItem.count({
      where: { userId: user.id },
    });

    if (currentItemCount >= BIN_ITEMS_LIMIT) {
      // Find and delete the oldest item
      const oldestItem = await prisma.binItem.findFirst({
        where: { userId: user.id },
        orderBy: { createdAt: "asc" },
        include: { fileItem: true, textItem: true },
      });

      if (oldestItem) {
        // Capture related ids and keys up front
        const textItemId = oldestItem.textItemId ?? undefined;
        const fileItemId = oldestItem.fileItemId ?? undefined;
        const fileKey = oldestItem.fileItem?.key ?? undefined;

        // Delete file from S3 storage first (non-DB side effect)
        if (fileKey) {
          await deleteObjectByKey(fileKey);
        }

        // Delete the bin item record next to avoid onDelete cascades from child deletions
        await prisma.binItem.delete({
          where: { id: oldestItem.id },
        });

        // Finally, clean up linked entities (these will not cascade now)
        if (textItemId) {
          await prisma.textItem.delete({
            where: { id: textItemId },
          });
        }
        if (fileItemId) {
          await prisma.fileItem.delete({
            where: { id: fileItemId },
          });
        }
      }
    }

    // File flow
    if (
      body?.file?.originalName &&
      body?.file?.contentType &&
      (body?.file?.size ?? 0) > 0
    ) {
      if (body.file.size > MAX_FILE_SIZE) {
        return NextResponse.json(
          {
            error: `${(body.file.size / 1024 / 1024).toFixed(2)}MB file size exceeds the ${MAX_FILE_SIZE / 1024 / 1024}MB limit`,
          },
          { status: 400 }
        );
      }
      const objectKey = `${user.id}/${crypto.randomUUID()}`;
      const uploadUrl = await createPresignedPutUrl({
        key: objectKey,
        contentType: body.file.contentType,
      });
      const file = await prisma.fileItem.create({
        data: {
          provider: "S3",
          bucket: getBucketName(),
          key: objectKey,
          originalName: body.file.originalName,
          contentType: body.file.contentType,
          size: BigInt(body.file.size),
          imageWidth: body.file.imageWidth ?? null,
          imageHeight: body.file.imageHeight ?? null,
        },
      });
      const bin = await prisma.binItem.create({
        data: { userId: user.id, kind: "FILE", fileItemId: file.id },
        include: { fileItem: true, textItem: true },
      });
      return NextResponse.json(serializeForJson({ item: bin, uploadUrl }), {
        status: 201,
      });
    }

    // Text flow
    const content =
      typeof body?.content === "string" ? body.content.trim() : "";
    if (!content) {
      return NextResponse.json(
        { error: "Provide 'content' (text) or 'file' metadata" },
        { status: 400 }
      );
    }

    // Check character limit
    if (content.length > MAX_CHAR_LIMIT) {
      return NextResponse.json(
        {
          error: `Text content (${content.length} characters) exceeds the ${MAX_CHAR_LIMIT} character limit`,
        },
        { status: 400 }
      );
    }

    // Check if content contains a URL and fetch OG data
    let ogData: OgData | null = null;
    const url = extractFirstUrl(content);
    if (url && isUrl(url)) {
      try {
        const ogEndpoint = new URL(
          "/api/og",
          process.env.NEXT_PUBLIC_BASE_URL ||
            `http://localhost:${process.env.PORT || 3000}`
        );
        const ogRes = await fetch(ogEndpoint, {
          method: "POST",
          headers: {
            Authorization: authHeader || "",
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ url }),
        });

        if (ogRes.ok) {
          const ogResult = (await ogRes.json()) as { og?: OgData };
          ogData = ogResult.og ?? null;
        }
      } catch (error) {
        console.error("Error fetching OG data on upload:", error);
        // Continue without OG data
      }
    }

    // Create text item with OG data if available
    const text = await prisma.textItem.create({
      data: {
        content,
        ogDataFetched: url && isUrl(url) ? true : false,
        ogTitle: ogData?.title ?? null,
        ogDescription: ogData?.description ?? null,
        ogImage: ogData?.image ?? null,
        ogImageWidth: ogData?.imageWidth ?? null,
        ogImageHeight: ogData?.imageHeight ?? null,
        ogIcon: ogData?.icon ?? null,
        ogSiteName: ogData?.siteName ?? null,
      },
    });
    const item = await prisma.binItem.create({
      data: {
        userId: user.id,
        kind: "TEXT",
        textItemId: text.id,
      },
      include: { textItem: true, fileItem: true },
    });

    return NextResponse.json(serializeForJson(item), { status: 201 });
  } catch (error) {
    const typed = error as Error & { statusCode?: number };
    return NextResponse.json(
      { error: typed.message },
      { status: typed.statusCode ?? 401 }
    );
  }
}
