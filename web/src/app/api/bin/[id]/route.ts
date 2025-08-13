import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { createPresignedGetUrl, deleteObjectByKey } from "@/lib/s3";
import { verifyAccessToken } from "@/lib/verifyAccessToken";

export async function DELETE(
	req: Request,
	{ params }: { params: Promise<{ id: string }> },
) {
	try {
		const payload = await verifyAccessToken(
			req.headers.get("authorization") ?? undefined,
		);
		const auth0Sub = payload.sub;
		const { id } = await params;

		if (!id || typeof id !== "string") {
			return NextResponse.json({ error: "Missing id" }, { status: 400 });
		}

		const user = await prisma.user.findUnique({
			where: { auth0Id: auth0Sub },
			select: { id: true },
		});

		if (!user) {
			return NextResponse.json({ error: "Item not found" }, { status: 404 });
		}

		const item = await prisma.binItem.findFirst({
			where: { id, userId: user.id },
			include: { textItem: true, fileItem: true },
		});
		if (!item) {
			return NextResponse.json({ error: "Item not found" }, { status: 404 });
		}

		// Capture related ids and keys up front
		const textItemId = item.textItemId ?? undefined;
		const fileItemId = item.fileItemId ?? undefined;
		const fileKey = item.fileItem?.key ?? undefined;

		// Delete file from storage first (non-DB side effect)
		if (fileKey) {
			await deleteObjectByKey(fileKey);
		}

		// Delete the bin item record next to avoid onDelete cascades from child deletions
		await prisma.binItem.delete({ where: { id: item.id } });

		// Finally, clean up linked entities (these will not cascade now)
		if (textItemId) {
			await prisma.textItem.delete({ where: { id: textItemId } });
		}
		if (fileItemId) {
			await prisma.fileItem.delete({ where: { id: fileItemId } });
		}

		return new NextResponse(null, { status: 204 });
	} catch (error) {
		const typed = error as Error & { statusCode?: number };
		return NextResponse.json(
			{ error: typed.message },
			{ status: typed.statusCode ?? 401 },
		);
	}
}

export async function GET(
	req: Request,
	{ params }: { params: Promise<{ id: string }> },
) {
	try {
		const payload = await verifyAccessToken(
			req.headers.get("authorization") ?? undefined,
		);
		const auth0Sub = payload.sub;

		const { id } = await params;
		if (!id || typeof id !== "string") {
			return NextResponse.json({ error: "Missing id" }, { status: 400 });
		}

		const user = await prisma.user.findUnique({
			where: { auth0Id: auth0Sub },
			select: { id: true },
		});
		if (!user)
			return NextResponse.json({ error: "Not found" }, { status: 404 });

		const item = await prisma.binItem.findFirst({
			where: { id, userId: user.id },
			include: { fileItem: true },
		});
		if (!item || item.kind !== "FILE" || !item.fileItem?.key) {
			return NextResponse.json({ error: "Not a file item" }, { status: 400 });
		}

		const url = await createPresignedGetUrl({ key: item.fileItem.key });
		return NextResponse.json({ url });
	} catch (error) {
		const typed = error as Error & { statusCode?: number };
		return NextResponse.json(
			{ error: typed.message },
			{ status: typed.statusCode ?? 401 },
		);
	}
}
