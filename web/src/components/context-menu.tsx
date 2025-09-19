"use client";

import { Loader2, LogOutIcon, SettingsIcon } from "lucide-react";
import { redirect } from "next/navigation";
import { useState } from "react";
import {
	DropdownMenu,
	DropdownMenuContent,
	DropdownMenuItem,
	DropdownMenuSeparator,
	DropdownMenuTrigger,
} from "@/components/ui/dropdown-button";
import { OMNIBIN_ROUTES } from "@/routes";
import { ThemeToggle } from "./theme-toggle";
import { Button } from "./ui/button";

export function ContextMenu({ loggedIn }: { loggedIn: boolean }) {
	const [loggingOut, setLoggingOut] = useState(false);

	return (
		<DropdownMenu>
			<DropdownMenuTrigger asChild>
				<Button variant="outline" size="icon" className="p-3">
					<SettingsIcon className="size-4" />
				</Button>
			</DropdownMenuTrigger>
			<DropdownMenuContent className="w-56" align="start" collisionPadding={12}>
				{loggedIn && (
					<>
						<DropdownMenuItem
							className="cursor-pointer"
							onClick={() => {
								setLoggingOut(true);
								redirect(OMNIBIN_ROUTES.LOGOUT);
							}}
						>
							{loggingOut ? (
								<Loader2 className="size-3 animate-spin" />
							) : (
								<LogOutIcon className="size-3" />
							)}
							Log out
						</DropdownMenuItem>
						<DropdownMenuSeparator />
					</>
				)}
				<ThemeToggle />
			</DropdownMenuContent>
		</DropdownMenu>
	);
}
