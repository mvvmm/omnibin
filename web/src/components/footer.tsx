import Link from "next/link";

export function Footer() {
	return (
		<footer
			className="relative z-10 border-t"
			style={{ borderColor: "var(--border)" }}
		>
			<div className="mx-auto max-w-6xl py-6 px-4">
				<div className="flex flex-col items-center justify-between gap-4 sm:flex-row">
					<div className="text-sm" style={{ color: "var(--muted-80)" }}>
						© {new Date().getFullYear()}{" "}
						<a
							href="https://github.com/mvvmm"
							target="_blank"
							rel="noopener noreferrer"
							className="transition-colors hover:underline"
							style={{ color: "var(--muted-80)" }}
						>
							mvm
						</a>
						.
					</div>
					<div className="flex gap-6">
						<Link
							href="/privacy-policy"
							className="text-sm transition-colors hover:underline"
							style={{ color: "var(--muted-80)" }}
						>
							Privacy Policy
						</Link>
						<Link
							href="/support"
							className="text-sm transition-colors hover:underline"
							style={{ color: "var(--muted-80)" }}
						>
							Support
						</Link>
						<a
							href="https://github.com/mvvmm/omnibin"
							target="_blank"
							rel="noopener noreferrer"
							className="text-sm transition-colors hover:underline"
							style={{ color: "var(--muted-80)" }}
						>
							GitHub
						</a>
						<a
							href="https://apps.apple.com/us/app/omnibin/id6752793228"
							target="_blank"
							rel="noopener noreferrer"
							className="text-sm transition-colors hover:underline"
							style={{ color: "var(--muted-80)" }}
						>
							iOS App
						</a>
					</div>
				</div>
			</div>
		</footer>
	);
}
