import { Comfortaa, Geist, Geist_Mono } from "next/font/google";

export const comfortaa = Comfortaa({
	weight: ["300", "400", "500", "600", "700"],
	subsets: ["latin"],
	variable: "--font-comfortaa",
	display: "swap",
});

export const geistSans = Geist({
	variable: "--font-geist-sans",
	subsets: ["latin"],
});

export const geistMono = Geist_Mono({
	variable: "--font-geist-mono",
	subsets: ["latin"],
});
