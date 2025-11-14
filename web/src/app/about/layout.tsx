import { ContextMenu } from "@/components/context-menu";
import { HomeLogo } from "@/components/home-logo";
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
				<HomeLogo />
				<ContextMenu loggedIn={!!session} />
			</div>
			{children}
		</>
	);
}
