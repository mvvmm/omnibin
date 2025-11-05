import type { Metadata } from "next";
import "./globals.css";
import { Analytics } from "@vercel/analytics/next";
import { SpeedInsights } from "@vercel/speed-insights/next";
import { Footer } from "@/components/footer";
import { ThemeProvider } from "@/components/theme-provider";
import { Toaster } from "@/components/ui/sonner";
import { comfortaa, geistMono, geistSans } from "@/fonts";

export const metadata: Metadata = {
	title: {
		template: "omnibin • %s",
		default: "omnibin",
	},
	description:
		"Seamless cross-platform clipboard. Move text, images, and files between devices with ease. Copy. Paste. Anywhere.",
	authors: [{ name: "mvm" }],
	creator: "mvm",
	formatDetection: {
		email: false,
		address: false,
		telephone: false,
	},
	metadataBase: new URL(process.env.NEXT_PUBLIC_BASE_URL || "https://omnib.in"),
	openGraph: {
		type: "website",
		locale: "en_US",
		siteName: "omnibin",
	},
};

export default function RootLayout({
	children,
}: Readonly<{
	children: React.ReactNode;
}>) {
	return (
		<html
			suppressHydrationWarning
			lang="en"
			className={`${comfortaa.variable} ${geistSans.variable} ${geistMono.variable}`}
		>
			<body
				className="antialiased"
				style={{
					backgroundImage:
						"linear-gradient(to bottom right, var(--bg-from), var(--bg-via), var(--bg-to))",
					backgroundAttachment: "fixed",
				}}
			>
				<ThemeProvider>
					{/* Fixed background elements that cover the entire viewport */}
					<div className="fixed inset-0 pointer-events-none">
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

					{/* Content container with relative positioning */}
					<div className="relative z-10 min-h-screen flex flex-col">
						<main className="flex-1">{children}</main>
						<Footer />
					</div>
					<Analytics />
					<SpeedInsights />
					<Toaster />
				</ThemeProvider>
			</body>
		</html>
	);
}
