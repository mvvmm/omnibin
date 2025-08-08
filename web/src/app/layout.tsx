import type { Metadata } from "next";
import "./globals.css";
import { ThemeProvider } from "@/components/theme-provider";
import { ThemeToggle } from "@/components/theme-toggle";
import { comfortaa, geistMono, geistSans } from "@/fonts";

export const metadata: Metadata = {
	title: "omnibin",
	description: `cross-platform copy/paste`,
	icons: {
		icon: "/favicons/favicon-96x96.png",
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
			<body className="antialiased">
				<ThemeProvider>
					<div className="pointer-events-none fixed inset-x-0 top-0 z-50 flex justify-end p-4">
						<div className="pointer-events-auto">
							<ThemeToggle />
						</div>
					</div>
					{children}
				</ThemeProvider>
			</body>
		</html>
	);
}
