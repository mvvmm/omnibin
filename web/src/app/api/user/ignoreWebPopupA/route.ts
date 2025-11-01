import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { verifyAccessToken } from "@/lib/verifyAccessToken";

export async function PATCH(req: Request) {
	try {
		const payload = await verifyAccessToken(
			req.headers.get("authorization") ?? undefined,
		);
		const auth0Sub = payload.sub;

		const user = await prisma.user.findUnique({
			where: { auth0Id: auth0Sub },
			select: { id: true },
		});

		if (!user) {
			return NextResponse.json({ error: "User not found" }, { status: 404 });
		}

		await prisma.user.update({
			where: { id: user.id },
			data: {
				ignoreWebPopupA: true,
			},
		});

		return NextResponse.json({ success: true });
	} catch (error) {
		const typed = error as Error & { statusCode?: number };
		console.error("Error in PATCH /api/user/ignoreWebPopupA:", typed.message);
		return NextResponse.json(
			{ error: typed.message },
			{ status: typed.statusCode ?? 500 },
		);
	}
}

