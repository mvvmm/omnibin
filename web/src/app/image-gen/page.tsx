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

	// Linkedin promo
	return (
		<div className="flex min-h-screen items-center justify-center p-4">
			{/* 1200x900 promo image container */}
			<div className="relative" style={{ width: "800px", height: "400px" }}>
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
				<Card className="relative z-10 flex h-full w-full flex-col items-center justify-between overflow-hidden rounded-none glass">
					{/* Top section - Logo, tagline, and App Store badge */}
					<div className="flex flex-col items-center space-y-6 pt-8">
						{/* Logo */}
						<div className="flex items-center justify-center">
							<Image
								src="/omnibin-logo.webp"
								alt="omnibin logo"
								width={400}
								height={120}
								priority
								className="h-auto w-auto"
							/>
						</div>

						{/* Tagline */}
						<h1
							className="font-comfortaa text-5xl font-semibold tracking-tight"
							style={{ color: "var(--foreground)" }}
						>
							Copy. Paste. Anywhere.
						</h1>

						{/* App Store badge */}
						<div className="flex items-center justify-center gap-3 py-4">
							<span className="btn-omnibin !px-4 !py-2 !rounded-md">
								omnib.in
							</span>
							or
							<Image
								src="/popups/a/download-on-app-store-white.svg"
								alt="Download on the App Store"
								width={120}
								height={40}
								priority
							/>
						</div>
					</div>
				</Card>
			</div>
		</div>
	);

	// app store promo image
	// return (
	// 	<div className="flex min-h-screen items-center justify-center p-4">
	// 		{/* 1200x900 promo image container */}
	// 		<div className="relative" style={{ width: "1000px", height: "800px" }}>
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
	// 				className="relative z-10 flex h-full w-full flex-col items-center justify-between overflow-hidden rounded-none"
	// 				style={{
	// 					backgroundColor: "var(--card-bg)",
	// 					borderColor: "var(--border)",
	// 				}}
	// 			>
	// 				{/* Top section - Logo, tagline, and App Store badge */}
	// 				<div className="flex flex-col items-center space-y-6 pt-8">
	// 					{/* Logo */}
	// 					<div className="flex items-center justify-center">
	// 						<Image
	// 							src="/omnibin-logo.webp"
	// 							alt="omnibin logo"
	// 							width={400}
	// 							height={120}
	// 							priority
	// 							className="h-auto w-auto"
	// 						/>
	// 					</div>

	// 					{/* Tagline */}
	// 					<h1
	// 						className="font-comfortaa text-5xl font-semibold tracking-tight"
	// 						style={{ color: "var(--foreground)" }}
	// 					>
	// 						Copy. Paste. Anywhere.
	// 					</h1>

	// 					{/* App Store badge */}
	// 					<div className="flex items-center justify-center py-4">
	// 						<Image
	// 							src="/popups/a/download-on-app-store-white.svg"
	// 							alt="Download on the App Store"
	// 							width={150}
	// 							height={50}
	// 							priority
	// 						/>
	// 					</div>
	// 				</div>

	// 				{/* Middle section - iPhone and iPad (will overflow at bottom) */}
	// 				<div className="flex items-start justify-center gap-8 flex-1 relative">
	// 					{/* iPhone */}
	// 					<div className="flex-shrink-0">
	// 						<Image
	// 							src="/popups/a/iphone.png"
	// 							alt="iPhone"
	// 							width={320}
	// 							height={640}
	// 							priority
	// 							className="h-auto w-auto drop-shadow-2xl"
	// 						/>
	// 					</div>

	// 					{/* iPad */}
	// 					<div className="flex-shrink-0">
	// 						<Image
	// 							src="/popups/a/ipad.png"
	// 							alt="iPad"
	// 							width={500}
	// 							height={667}
	// 							priority
	// 							className="h-auto w-auto drop-shadow-2xl"
	// 						/>
	// 					</div>
	// 				</div>
	// 			</Card>
	// 		</div>
	// 	</div>
	// );

	// ios preview
	// return (
	// 	<div className="flex min-h-screen items-center justify-center p-4">
	// 		{/* 414x896 iOS preview container */}
	// 		<div className="relative" style={{ width: "414px", height: "896px" }}>
	// 			{/* Background with floating orbs and grid - same as layout */}
	// 			<div className="absolute inset-0 pointer-events-none">
	// 				{/* Blob 1 */}
	// 				<div
	// 					className="absolute -top-16 -left-16 h-[20rem] w-[20rem] rounded-full blur-3xl"
	// 					style={{
	// 						backgroundColor: "var(--blob-1)",
	// 						opacity: "var(--blob-opacity)",
	// 					}}
	// 				/>

	// 				{/* Blob 2 */}
	// 				<div
	// 					className="absolute -bottom-20 -right-20 h-[24rem] w-[24rem] rounded-full blur-3xl"
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
	// 				className="relative z-10 flex h-full w-full flex-col items-center justify-center p-8 text-center rounded-none"
	// 				style={{
	// 					backgroundColor: "var(--card-bg)",
	// 					borderColor: "var(--border)",
	// 				}}
	// 			>
	// 				{/* Logo */}
	// 				<div className="mb-6 flex items-center justify-center">
	// 					<Image
	// 						src="/omnibin-logo.webp"
	// 						alt="omnibin logo"
	// 						width={500}
	// 						height={150}
	// 						priority
	// 						className="h-auto w-auto"
	// 					/>
	// 				</div>

	// 				{/* Title */}
	// 				<h1
	// 					className="mb-3 font-comfortaa text-5xl font-bold tracking-tight"
	// 					style={{ color: "var(--foreground)" }}
	// 				>
	// 					Copy. Paste. Anywhere.
	// 				</h1>

	// 				{/* Description */}
	// 				<p
	// 					className="max-w-3xl text-xl leading-relaxed"
	// 					style={{ color: "var(--muted-80)" }}
	// 				>
	// 					Seamless cross‑platform clipboard. Move text, images, and files
	// 					between devices with ease.
	// 				</p>
	// 			</Card>
	// 		</div>
	// 	</div>
	// );

	// ipados preview
	// return (
	// 	<div className="flex min-h-screen items-center justify-center p-4">
	// 		{/* 688x917.33 iPadOS preview container */}
	// 		<div className="relative" style={{ width: "688px", height: "917.33px" }}>
	// 			{/* Background with floating orbs and grid - same as layout */}
	// 			<div className="absolute inset-0 pointer-events-none">
	// 				{/* Blob 1 */}
	// 				<div
	// 					className="absolute -top-24 -left-24 h-[28rem] w-[28rem] rounded-full blur-3xl"
	// 					style={{
	// 						backgroundColor: "var(--blob-1)",
	// 						opacity: "var(--blob-opacity)",
	// 					}}
	// 				/>

	// 				{/* Blob 2 */}
	// 				<div
	// 					className="absolute -bottom-32 -right-32 h-[32rem] w-[32rem] rounded-full blur-3xl"
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
	// 				className="relative z-10 flex h-full w-full flex-col items-center justify-center p-8 text-center rounded-none"
	// 				style={{
	// 					backgroundColor: "var(--card-bg)",
	// 					borderColor: "var(--border)",
	// 				}}
	// 			>
	// 				{/* Logo */}
	// 				<div className="mb-6 flex items-center justify-center">
	// 					<Image
	// 						src="/omnibin-logo.webp"
	// 						alt="omnibin logo"
	// 						width={600}
	// 						height={180}
	// 						priority
	// 						className="h-auto w-auto"
	// 					/>
	// 				</div>

	// 				{/* Title */}
	// 				<h1
	// 					className="mb-3 font-comfortaa text-6xl font-bold tracking-tight"
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

	// github readme header
	// return (
	// 	<div className="flex min-h-screen items-center justify-center p-4">
	// 		{/* 1200x630 card container */}
	// 		<div className="relative" style={{ width: "1280px", height: "450px" }}>
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
	// 				className="relative z-10 flex h-full w-full flex-col items-center justify-center p-8 text-center rounded-none"
	// 				style={{
	// 					backgroundColor: "var(--card-bg)",
	// 					borderColor: "var(--border)",
	// 				}}
	// 			>
	// 				{/* Logo */}
	// 				<div className="mb-6 flex items-center justify-center">
	// 					<Image
	// 						src="/omnibin-logo.webp"
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
	// 						src="/omnibin-logo.webp"
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
