import BinListLoading from "@/components/bin/BinListLoading";
import CreateItemFormLoading from "@/components/bin/CreateItemFormLoading";
import { Card } from "@/components/ui/card";

export default function Loading() {
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
					<CreateItemFormLoading />
					<BinListLoading />
				</div>
			</Card>
		</div>
	);
}
