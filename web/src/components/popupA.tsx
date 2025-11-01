"use client";

import { XIcon } from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { useState } from "react";
import { dismissPopupA } from "@/actions/dismissPopupA";

const APP_STORE_URL = "https://apps.apple.com/us/app/omnibin/id6752793228";

export function PopupA() {
	const [open, setOpen] = useState(true);

	const handleClose = () => {
		setOpen(false);
		// Dismiss the popup in the database (fire and forget)
		void dismissPopupA();
	};

	if (!open) {
		return null;
	}

	return (
		<>
			{/* Backdrop overlay - only on small screens */}
			<div className="fixed inset-0 z-40 backdrop-blur-[1px] bg-black/40 md:hidden" />

			<div className="fixed left-1/2 top-1/2 z-50 w-[90%] -translate-x-1/2 -translate-y-1/2 rounded-lg bg-gradient-to-r from-omnibin-primary to-omnibin-secondary p-[2px] shadow-2xl md:w-auto md:max-w-md md:bottom-4 md:right-4 md:left-auto md:top-auto md:translate-x-0 md:translate-y-0">
				<div
					className="rounded-lg border p-6 backdrop-blur-md"
					style={{
						backgroundColor: "var(--card-bg-opaque)",
						borderColor: "var(--border)",
					}}
				>
					<button
						type="button"
						onClick={handleClose}
						className="absolute top-4 right-4 rounded-xs opacity-70 transition-opacity hover:opacity-100 focus:ring-2 focus:ring-offset-2 focus:outline-hidden cursor-pointer"
						aria-label="Close"
					>
						<XIcon className="size-4" />
					</button>

					<div className="space-y-4">
						<div className="space-y-2">
							<h3
								className="text-lg font-semibold"
								style={{ color: "var(--foreground)" }}
							>
								Download omnibin on the App Store
							</h3>
							<p
								className="text-sm"
								style={{ color: "var(--muted-foreground)" }}
							>
								omnibin works even better when you pair the web app with the iOS
								app. Seamlessly sync between your Desktop, iPhone, and iPad for
								the ultimate cross-platform clipboard experience!
							</p>
						</div>

						<Link
							href={APP_STORE_URL}
							target="_blank"
							rel="noopener noreferrer"
							className="block"
							onClick={handleClose}
						>
							<Image
								src="/popups/a/final-image-gen.png"
								alt="Download omnibin on the App Store"
								width={1816}
								height={1454}
								className="w-full h-auto rounded-lg cursor-pointer hover:opacity-90 transition-opacity"
								priority
							/>
						</Link>
					</div>
				</div>
			</div>
		</>
	);
}
