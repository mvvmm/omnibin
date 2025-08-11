import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { verifyAccessToken } from "@/lib/verifyAccessToken";

export async function GET(req: Request) {
	try {
		const payload = await verifyAccessToken(
			req.headers.get("authorization") ?? undefined,
		);
		const auth0Sub = payload.sub;

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
		});

		return NextResponse.json({ items });
	} catch (error) {
		const typed = error as Error & { statusCode?: number };
		return NextResponse.json(
			{ error: typed.message },
			{ status: typed.statusCode ?? 401 },
		);
	}
}

export async function POST(req: Request) {
	try {
		const payload = await verifyAccessToken(
			req.headers.get("authorization") ?? undefined,
		);
		const auth0Sub = payload.sub;

		const body = await req.json().catch(() => undefined);
		const content =
			typeof body?.content === "string" ? body.content.trim() : "";
		if (!content) {
			return NextResponse.json(
				{ error: "Field 'content' is required and must be a non-empty string" },
				{ status: 400 },
			);
		}

		// Ensure user exists
		const user = await prisma.user.upsert({
			where: { auth0Id: auth0Sub },
			update: {},
			create: { auth0Id: auth0Sub },
			select: { id: true },
		});

		const item = await prisma.binItem.create({
			data: {
				userId: user.id,
				content,
			},
		});

		return NextResponse.json(item, { status: 201 });
	} catch (error) {
		const typed = error as Error & { statusCode?: number };
		return NextResponse.json(
			{ error: typed.message },
			{ status: typed.statusCode ?? 401 },
		);
	}
}
