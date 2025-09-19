"use client";

import { useTheme } from "next-themes";
import { Button } from "@/components/ui/button";

export function ThemeToggle() {
	const { setTheme } = useTheme();

	return (
		<div
			className="flex w-full"
			style={{
				backgroundColor: "var(--card-bg)",
				borderColor: "var(--border)",
			}}
		>
			<Button
				variant="ghost"
				size="sm"
				className="text-xs rounded-sm rounded-r-none flex-1"
				onClick={() => setTheme("light")}
				type="button"
			>
				Light
			</Button>
			<Button
				variant="ghost"
				size="sm"
				className="text-xs rounded-sm rounded-none flex-1"
				onClick={() => setTheme("system")}
				type="button"
			>
				System
			</Button>
			<Button
				variant="ghost"
				size="sm"
				className="text-xs rounded-sm rounded-l-none flex-1"
				onClick={() => setTheme("dark")}
				type="button"
			>
				Dark
			</Button>
		</div>
	);
}
