import type { Metadata } from "next";
import Image from "next/image";
import { notFound } from "next/navigation";
import { Card } from "@/components/ui/card";

export const metadata: Metadata = {
	title: "Test - OG Image Generator",
	description: "Test page for generating OG/Twitter images",
};

export default function Page() {
	// Check if we're in development/localhost environment
	const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || "";

	// Only allow localhost access
	if (!baseUrl.includes("localhost") && !baseUrl.includes("127.0.0.1")) {
		notFound();
	}

	// github readme header
	return (
		<div className="flex min-h-screen items-center justify-center p-4">
			{/* 1200x630 card container */}
			<div className="relative" style={{ width: "1280px", height: "640px" }}>
				{/* Background with floating orbs and grid - same as layout */}
				<div className="absolute inset-0 pointer-events-none">
					{/* Blob 1 */}
					<div
						className="absolute -top-32 -left-32 h-[42rem] w-[42rem] rounded-full blur-3xl"
						style={{
							backgroundColor: "var(--blob-1)",
							opacity: "var(--blob-opacity)",
						}}
					/>

					{/* Blob 2 */}
					<div
						className="absolute -bottom-40 -right-40 h-[46rem] w-[46rem] rounded-full blur-3xl"
						style={{
							backgroundColor: "var(--blob-2)",
							opacity: "var(--blob-opacity)",
						}}
					/>

					{/* Grid */}
					<div
						className="absolute inset-0 opacity-20 [mask-image:radial-gradient(60rem_60rem_at_center,white,transparent)]"
						style={{
							backgroundImage:
								"linear-gradient(to right, var(--grid-line) 1px, transparent 1px), linear-gradient(to bottom, var(--grid-line) 1px, transparent 1px)",
							backgroundSize: "36px 36px",
						}}
					/>
				</div>

				{/* Main card */}
				<Card
					className="relative z-10 flex h-full w-full flex-col items-center justify-center p-8 text-center rounded-none"
					style={{
						backgroundColor: "var(--card-bg)",
						borderColor: "var(--border)",
					}}
				>
					{/* Logo */}
					<div className="mb-6 flex items-center justify-center">
						<Image
							src="/omnibin-logo6.png"
							alt="omnibin logo"
							width={500}
							height={150}
							priority
							className="h-auto w-auto"
						/>
					</div>

					{/* Title */}
					<h1
						className="mb-3 font-comfortaa text-6xl font-semibold tracking-tight"
						style={{ color: "var(--foreground)" }}
					>
						Copy. Paste. Anywhere.
					</h1>

					{/* Description */}
					<p
						className="max-w-3xl text-2xl leading-relaxed"
						style={{ color: "var(--muted-80)" }}
					>
						Seamless cross‑platform clipboard. Move text, images, and files
						between devices with ease.
					</p>
				</Card>
			</div>
		</div>
	);

	// og image
	// return (
	// 	<div className="flex min-h-screen items-center justify-center p-4">
	// 		{/* 1200x630 card container */}
	// 		<div className="relative" style={{ width: "1200px", height: "630px" }}>
	// 			{/* Background with floating orbs and grid - same as layout */}
	// 			<div className="absolute inset-0 pointer-events-none">
	// 				{/* Blob 1 */}
	// 				<div
	// 					className="absolute -top-32 -left-32 h-[42rem] w-[42rem] rounded-full blur-3xl"
	// 					style={{
	// 						backgroundColor: "var(--blob-1)",
	// 						opacity: "var(--blob-opacity)",
	// 					}}
	// 				/>

	// 				{/* Blob 2 */}
	// 				<div
	// 					className="absolute -bottom-40 -right-40 h-[46rem] w-[46rem] rounded-full blur-3xl"
	// 					style={{
	// 						backgroundColor: "var(--blob-2)",
	// 						opacity: "var(--blob-opacity)",
	// 					}}
	// 				/>

	// 				{/* Grid */}
	// 				<div
	// 					className="absolute inset-0 opacity-20 [mask-image:radial-gradient(60rem_60rem_at_center,white,transparent)]"
	// 					style={{
	// 						backgroundImage:
	// 							"linear-gradient(to right, var(--grid-line) 1px, transparent 1px), linear-gradient(to bottom, var(--grid-line) 1px, transparent 1px)",
	// 						backgroundSize: "36px 36px",
	// 					}}
	// 				/>
	// 			</div>

	// 			{/* Main card */}
	// 			<Card
	// 				className="relative z-10 flex h-full w-full flex-col items-center justify-center p-8 text-center"
	// 				style={{
	// 					backgroundColor: "var(--card-bg)",
	// 					borderColor: "var(--border)",
	// 				}}
	// 			>
	// 				{/* Logo */}
	// 				<div className="mb-6 flex items-center justify-center">
	// 					<Image
	// 						src="/omnibin-logo6.png"
	// 						alt="omnibin logo"
	// 						width={500}
	// 						height={150}
	// 						priority
	// 						className="h-auto w-auto"
	// 					/>
	// 				</div>

	// 				{/* Title */}
	// 				<h1
	// 					className="mb-3 font-comfortaa text-6xl font-semibold tracking-tight"
	// 					style={{ color: "var(--foreground)" }}
	// 				>
	// 					Copy. Paste. Anywhere.
	// 				</h1>

	// 				{/* Description */}
	// 				<p
	// 					className="max-w-3xl text-2xl leading-relaxed"
	// 					style={{ color: "var(--muted-80)" }}
	// 				>
	// 					Seamless cross‑platform clipboard. Move text, images, and files
	// 					between devices with ease.
	// 				</p>
	// 			</Card>
	// 		</div>
	// 	</div>
	// );
}
