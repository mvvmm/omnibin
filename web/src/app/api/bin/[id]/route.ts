import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
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

		// Delete linked entities first (DB onDelete: Cascade would also handle, but be explicit)
		if (item.textItemId) {
			await prisma.textItem.delete({ where: { id: item.textItemId } });
		}
		if (item.fileItemId) {
			await prisma.fileItem.delete({ where: { id: item.fileItemId } });
		}

		await prisma.binItem.delete({ where: { id: item.id } });

		return new NextResponse(null, { status: 204 });
	} catch (error) {
		const typed = error as Error & { statusCode?: number };
		return NextResponse.json(
			{ error: typed.message },
			{ status: typed.statusCode ?? 401 },
		);
	}
}
