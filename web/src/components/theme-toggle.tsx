"use client";

import { useTheme } from "next-themes";
import { Button } from "@/components/ui/button";

export function ThemeToggle() {
	const { setTheme } = useTheme();

	return (
		<div
			className="flex items-center gap-1 rounded-md border backdrop-blur-md"
			style={{
				backgroundColor: "var(--card-bg)",
				borderColor: "var(--border)",
			}}
		>
			<Button
				variant="ghost"
				size="sm"
				className="text-xs rounded-r-none"
				onClick={() => setTheme("light")}
				type="button"
			>
				Light
			</Button>
			<Button
				variant="ghost"
				size="sm"
				className="text-xs rounded-none"
				onClick={() => setTheme("system")}
				type="button"
			>
				System
			</Button>
			<Button
				variant="ghost"
				size="sm"
				className="text-xs rounded-l-none"
				onClick={() => setTheme("dark")}
				type="button"
			>
				Dark
			</Button>
		</div>
	);
}
