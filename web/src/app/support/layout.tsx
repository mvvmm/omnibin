import Image from "next/image";
import Link from "next/link";
import { ContextMenu } from "@/components/context-menu";
import { auth0 } from "@/lib/auth0";

export default async function Layout({
	children,
}: Readonly<{
	children: React.ReactNode;
}>) {
	const session = await auth0.getSession();

	return (
		<>
			<div className="flex justify-between items-center p-4">
				<Link href="/?stay=true" aria-label="Go to home">
					<Image
						src="/omnibin-logo6.png"
						alt="omnibin logo"
						width={340}
						height={100}
						className="h-8 w-auto transition-transform duration-300 hover:scale-[1.02]"
						priority
					/>
				</Link>
				<ContextMenu loggedIn={!!session} />
			</div>
			{children}
		</>
	);
}
