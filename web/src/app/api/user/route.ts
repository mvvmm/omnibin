import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { verifyAccessToken } from "@/lib/verifyAccessToken";

export async function GET(req: Request) {
	try {
		const payload = await verifyAccessToken(
			req.headers.get("authorization") ?? undefined,
		);
		const auth0Sub = payload.sub;

		const user = await prisma.user.upsert({
			where: { auth0Id: auth0Sub },
			update: {},
			create: { auth0Id: auth0Sub },
			select: {
				id: true,
				ignoreWebPopupA: true,
			},
		});

		return NextResponse.json({ user });
	} catch (error) {
		const typed = error as Error & { statusCode?: number };
		console.error("Error in GET /api/user:", typed.message);
		return NextResponse.json(
			{ error: typed.message },
			{ status: typed.statusCode ?? 401 },
		);
	}
}

