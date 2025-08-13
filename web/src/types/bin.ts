export type TextItem = {
	id: string;
	content: string;
};

export type FileItem = {
	id: string;
	originalName: string;
	contentType: string;
	// BigInt from Prisma will serialize as string in JSON
	size: string | number;
	checksum?: string | null;
	preview?: string | null;
	imageWidth?: number | null;
	imageHeight?: number | null;
	expiresAt?: string | null;
};

export type BinItem = {
	id: string;
	userId: string;
	kind: "TEXT" | "FILE";
	textItem?: TextItem | null;
	fileItem?: FileItem | null;
	createdAt: string;
	updatedAt: string;
};
