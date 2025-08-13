import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { createPresignedPutUrl, getBucketName } from "@/lib/s3";
import { serializeForJson } from "@/lib/utils";
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
			include: { textItem: true, fileItem: true },
		});

		return NextResponse.json(serializeForJson({ items }));
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

		// File flow
		if (
			body?.file?.originalName &&
			body?.file?.contentType &&
			(body?.file?.size ?? 0) > 0
		) {
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
				{ status: 400 },
			);
		}
		const text = await prisma.textItem.create({ data: { content } });
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
			{ status: typed.statusCode ?? 401 },
		);
	}
}
