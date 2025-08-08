"use client";

import { useTheme } from "next-themes";

export function ThemeToggle() {
	const { setTheme } = useTheme();

	return (
		<div
			className="flex items-center gap-1 rounded-full border p-1 backdrop-blur-md"
			style={{
				backgroundColor: "var(--card-bg)",
				borderColor: "var(--border)",
			}}
		>
			<button
				type="button"
				onClick={() => setTheme("light")}
				className="rounded-full px-3 py-1 text-xs font-medium transition hover:opacity-80"
				style={{ color: "var(--foreground)", backgroundColor: "transparent" }}
			>
				Light
			</button>
			<button
				type="button"
				onClick={() => setTheme("system")}
				className="rounded-full px-3 py-1 text-xs font-medium transition hover:opacity-80"
				style={{ color: "var(--foreground)", backgroundColor: "transparent" }}
			>
				System
			</button>
			<button
				type="button"
				onClick={() => setTheme("dark")}
				className="rounded-full px-3 py-1 text-xs font-medium transition hover:opacity-80"
				style={{ color: "var(--foreground)", backgroundColor: "transparent" }}
			>
				Dark
			</button>
		</div>
	);
}
