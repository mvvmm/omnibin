import { OMNIBIN_API_ROUTES } from "@/routes";
import type { BinItem } from "@/types/bin";
import { BinListItem } from "./BinListItem";

export async function BinList({
	items,
	token,
}: {
	items: BinItem[];
	token: string;
}) {
	const getPreviewUrls = async () => {
		const candidates = items.filter(
			(i) =>
				i.kind === "FILE" &&
				i.fileItem &&
				i.fileItem.preview == null &&
				i.fileItem.contentType.startsWith("image/"),
		);
		for (const item of candidates) {
			try {
				const url = new URL(
					OMNIBIN_API_ROUTES.BIN_ITEM({ itemId: item.id }),
					process.env.NEXT_PUBLIC_BASE_URL,
				);
				const res = await fetch(url, {
					method: "GET",
					headers: { Authorization: `Bearer ${token}` },
				});
				const data = (await res.json()) as { url?: string };
				if (item.fileItem) {
					item.fileItem.preview = data.url ?? null;
				}
			} catch {
				if (item.fileItem) {
					item.fileItem.preview = null;
				}
			}
		}
	};

	await getPreviewUrls();

	if (items.length === 0)
		return <p className="text-muted-foreground">No items yet.</p>;

	return (
		<ul className="space-y-2">
			{items.map((item) => (
				<BinListItem key={item.id} item={item} token={token} />
			))}
		</ul>
	);
}
