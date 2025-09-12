import { BinList } from "@/components/bin/BinList";
import { CreateItemForm } from "@/components/bin/CreateItemForm";
import { Card } from "@/components/ui/card";
import { getAccessTokenOrReauth } from "@/lib/auth0";
import { OMNIBIN_API_ROUTES } from "@/routes";

import type { BinItem } from "@/types/bin";

export default async function Page() {
	const token = await getAccessTokenOrReauth();

	const url = new URL(OMNIBIN_API_ROUTES.BIN, process.env.NEXT_PUBLIC_BASE_URL);

	const res = await fetch(url, {
		method: "GET",
		headers: {
			Authorization: `Bearer ${token}`,
		},
		cache: "no-store",
	});

	if (!res.ok) {
		return (
			<div className="mx-auto flex min-h-screen max-w-6xl items-center justify-center px-4 py-12 sm:px-6 lg:px-8">
				<Card
					className="mx-auto w-full max-w-3xl p-6 md:p-8"
					style={{
						backgroundColor: "var(--card-bg)",
						borderColor: "var(--border)",
						gap: "0px",
					}}
				>
					<h1 className="text-2xl font-semibold text-foreground">Your Bin</h1>
					<p className="mt-2 text-sm text-muted-foreground">
						Failed to load your bin items ({res.status}).
					</p>
				</Card>
			</div>
		);
	}

	const data = (await res.json()) as { items: BinItem[] };
	const items = data.items ?? [];

	return (
		<div className="mx-auto flex max-w-6xl items-center justify-center px-4 py-12 sm:px-6 lg:px-8">
			<Card
				className="mx-auto w-full max-w-3xl p-6 md:p-8"
				style={{
					backgroundColor: "var(--card-bg)",
					borderColor: "var(--border)",
					gap: "0px",
				}}
			>
				<h1 className="text-2xl font-semibold text-foreground">Your Bin</h1>
				<div className="mt-4 space-y-4">
					<CreateItemForm token={token} numItems={items.length} />
					<BinList items={items} />
				</div>
			</Card>
		</div>
	);
}
