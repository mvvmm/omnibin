import { LogIn } from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { Card } from "@/components/ui/card";

export default function Home() {
	return (
		<div
			className="relative min-h-screen w-full overflow-hidden bg-gradient-to-br"
			style={{
				backgroundImage:
					"linear-gradient(to bottom right, var(--bg-from), var(--bg-via), var(--bg-to))",
			}}
		>
			{/* decorative background blobs */}
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

			{/* subtle grid overlay */}
			<div
				className="pointer-events-none absolute inset-0 opacity-20 [mask-image:radial-gradient(60rem_60rem_at_center,white,transparent)]"
				style={{
					backgroundImage:
						"linear-gradient(to right, var(--grid-line) 1px, transparent 1px), linear-gradient(to bottom, var(--grid-line) 1px, transparent 1px)",
					backgroundSize: "36px 36px",
				}}
			/>

			{/* content */}
			<div className="relative z-10 mx-auto flex min-h-screen max-w-6xl items-center justify-center px-4 py-12 sm:px-6 lg:px-8">
				<Card
					className="mx-auto w-full max-w-3xl p-8 text-center md:p-12"
					style={{
						backgroundColor: "var(--card-bg)",
						borderColor: "var(--border)",
					}}
				>
					<div className="flex items-center justify-center">
						<Image
							src="/omnibin-logo6.png"
							alt="omnibin logo"
							width={680}
							height={200}
							priority
							className="h-auto w-full max-w-[720px] drop-shadow-xl"
						/>
					</div>

					<h1
						className="mt-8 font-comfortaa text-4xl font-semibold tracking-tight sm:text-5xl md:text-6xl"
						style={{ color: "var(--foreground)" }}
					>
						Copy. Paste. Anywhere.
					</h1>
					<p
						className="mx-auto mt-4 max-w-2xl text-balance text-base sm:text-lg"
						style={{ color: "var(--muted-80)" }}
					>
						Seamless cross‑platform clipboard. Move text and files between
						devices with ease.
					</p>

					<div className="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row sm:gap-4">
						<Link
							href="/auth/login"
							className="inline-flex items-center justify-center rounded-xl bg-gradient-to-r from-accent-primary to-accent-secondary px-6 py-3 text-base font-semibold text-white shadow-lg shadow-accent-primary/30 transition-transform duration-200 hover:scale-[1.02] hover:shadow-xl focus:outline-none focus-visible:ring-2 focus-visible:ring-white/60"
						>
							Login to sync
							<LogIn className="ml-2 h-5 w-5" aria-hidden="true" />
						</Link>
					</div>

					<div className="mt-10 grid grid-cols-1 gap-4 text-left sm:grid-cols-3">
						<Card
							className="rounded-xl shadow-none p-4"
							style={{
								backgroundColor: "var(--card-bg)",
								borderColor: "var(--border)",
								color: "var(--foreground)",
							}}
						>
							<p className="text-sm">Fast, secure sync</p>
							<p className="mt-1 text-xs" style={{ color: "var(--muted-60)" }}>
								Backed by modern auth and storage.
							</p>
						</Card>
						<Card
							className="rounded-xl shadow-none p-4"
							style={{
								backgroundColor: "var(--card-bg)",
								borderColor: "var(--border)",
								color: "var(--foreground)",
							}}
						>
							<p className="text-sm">Multi‑device</p>
							<p className="mt-1 text-xs" style={{ color: "var(--muted-60)" }}>
								Use it on the web, Windows 11, iOS, macOS, and iPadOS.
							</p>
						</Card>
						<Card
							className="rounded-xl shadow-none p-4"
							style={{
								backgroundColor: "var(--card-bg)",
								borderColor: "var(--border)",
								color: "var(--foreground)",
							}}
						>
							<p className="text-sm">Simple by design</p>
							<p className="mt-1 text-xs" style={{ color: "var(--muted-60)" }}>
								One click to get started.
							</p>
						</Card>
					</div>
				</Card>
			</div>
		</div>
	);
}
