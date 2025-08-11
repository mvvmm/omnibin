import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { verifyAccessToken } from "@/lib/verifyAccessToken";

export async function DELETE(
	req: Request,
	{ params }: { params: { id: string } },
) {
	try {
		const payload = await verifyAccessToken(
			req.headers.get("authorization") ?? undefined,
		);
		const auth0Sub = payload.sub;
		const id = params.id;

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

		const result = await prisma.binItem.deleteMany({
			where: { id, userId: user.id },
		});

		if (result.count === 0) {
			return NextResponse.json({ error: "Item not found" }, { status: 404 });
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
