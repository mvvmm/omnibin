import Link from "next/link";

export function Footer() {
	return (
		<footer className="relative z-10 border-t">
			<div className="mx-auto max-w-6xl py-6 px-4">
				<div className="flex flex-col items-center justify-between gap-4 sm:flex-row">
					<div className="text-sm">
						© {new Date().getFullYear()}{" "}
						<a
							href="https://github.com/mvvmm"
							target="_blank"
							rel="noopener noreferrer"
							className="transition-colors hover:underline"
						>
							mvm
						</a>
						.
					</div>
					<div className="flex gap-6">
						<Link
							href="/about"
							className="text-sm transition-colors hover:underline"
						>
							About
						</Link>
						<Link
							href="/privacy-policy"
							className="text-sm transition-colors hover:underline"
						>
							Privacy Policy
						</Link>
						<Link
							href="/support"
							className="text-sm transition-colors hover:underline"
						>
							Support
						</Link>
						<a
							href="https://github.com/mvvmm/omnibin"
							target="_blank"
							rel="noopener noreferrer"
							className="text-sm transition-colors hover:underline"
						>
							GitHub
						</a>
						<a
							href="https://apps.apple.com/us/app/omnibin/id6752793228"
							target="_blank"
							rel="noopener noreferrer"
							className="text-sm transition-colors hover:underline"
						>
							iOS App
						</a>
					</div>
				</div>
			</div>
		</footer>
	);
}
