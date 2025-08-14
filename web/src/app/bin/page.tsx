import { BinList } from "@/components/bin/BinList";
import { CreateItemForm } from "@/components/bin/CreateItemForm";
import { Card } from "@/components/ui/card";
import { getAccessTokenOrReauth } from "@/lib/auth0";

import type { BinItem } from "@/types/bin";

export const dynamic = "force-dynamic";

export default async function Page() {
	const token = await getAccessTokenOrReauth();

	const res = await fetch(`${process.env.OMNIBIN_API_BASE_URL}/bin`, {
		method: "GET",
		headers: {
			Authorization: `Bearer ${token}`,
		},
		cache: "no-store",
	});

	if (!res.ok) {
		return (
			<div
				className="relative min-h-screen w-full overflow-hidden bg-gradient-to-br"
				style={{
					backgroundImage:
						"linear-gradient(to bottom right, var(--bg-from), var(--bg-via), var(--bg-to))",
				}}
			>
				<div
					className="pointer-events-none absolute -top-32 -left-32 h-[42rem] w-[42rem] rounded-full blur-3xl"
					style={{
						backgroundColor: "var(--blob-1)",
						opacity: "var(--blob-opacity)",
					}}
				/>
				<div
					className="pointer-events-none absolute -bottom-40 -right-40 h-[46rem] w-[46rem] rounded-full blur-3xl"
					style={{
						backgroundColor: "var(--blob-2)",
						opacity: "var(--blob-opacity)",
					}}
				/>

				<div
					className="pointer-events-none absolute inset-0 opacity-20 [mask-image:radial-gradient(60rem_60rem_at_center,white,transparent)]"
					style={{
						backgroundImage:
							"linear-gradient(to right, var(--grid-line) 1px, transparent 1px), linear-gradient(to bottom, var(--grid-line) 1px, transparent 1px)",
						backgroundSize: "36px 36px",
					}}
				/>

				<div className="relative z-10 mx-auto flex min-h-screen max-w-6xl items-center justify-center px-4 py-12 sm:px-6 lg:px-8">
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
			</div>
		);
	}

	const data = (await res.json()) as { items: BinItem[] };
	const items = data.items ?? [];

	return (
		<div
			className="relative min-h-screen w-full overflow-hidden bg-gradient-to-br"
			style={{
				backgroundImage:
					"linear-gradient(to bottom right, var(--bg-from), var(--bg-via), var(--bg-to))",
			}}
		>
			<div
				className="pointer-events-none absolute -top-32 -left-32 h-[42rem] w-[42rem] rounded-full blur-3xl"
				style={{
					backgroundColor: "var(--blob-1)",
					opacity: "var(--blob-opacity)",
				}}
			/>
			<div
				className="pointer-events-none absolute -bottom-40 -right-40 h-[46rem] w-[46rem] rounded-full blur-3xl"
				style={{
					backgroundColor: "var(--blob-2)",
					opacity: "var(--blob-opacity)",
				}}
			/>

			<div
				className="pointer-events-none absolute inset-0 opacity-20 [mask-image:radial-gradient(60rem_60rem_at_center,white,transparent)]"
				style={{
					backgroundImage:
						"linear-gradient(to right, var(--grid-line) 1px, transparent 1px), linear-gradient(to bottom, var(--grid-line) 1px, transparent 1px)",
					backgroundSize: "36px 36px",
				}}
			/>

			<div className="relative z-10 mx-auto flex min-h-screen max-w-6xl items-center justify-center px-4 py-12 sm:px-6 lg:px-8">
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
						<CreateItemForm token={token} />
						<BinList items={items} token={token} />
					</div>
				</Card>
			</div>
		</div>
	);
}
