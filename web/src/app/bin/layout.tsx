import Image from "next/image";
import Link from "next/link";
import { redirect } from "next/navigation";
import { ContextMenu } from "@/components/context-menu";
import { PopupA } from "@/components/popupA";
import { auth0, getAccessTokenOrReauth } from "@/lib/auth0";
import { OMNIBIN_API_ROUTES, OMNIBIN_ROUTES } from "@/routes";

export default async function Layout({
	children,
}: Readonly<{
	children: React.ReactNode;
}>) {
	const session = await auth0.getSession();

	if (!session) {
		redirect(OMNIBIN_ROUTES.LOGIN);
	}

	// Fetch or create user and check popup status
	const accessToken = await getAccessTokenOrReauth();
	const endpoint = new URL(
		OMNIBIN_API_ROUTES.USER,
		process.env.NEXT_PUBLIC_BASE_URL,
	);
	const response = await fetch(endpoint, {
		headers: {
			Authorization: `Bearer ${accessToken}`,
		},
		cache: "no-store",
	});

	if (!response.ok) {
		console.error("Failed to fetch user:", await response.text());
		redirect(OMNIBIN_ROUTES.LOGIN);
	}

	const { user } = await response.json();
	const shouldShowPopupA = !user.ignoreWebPopupA;

	return (
		<>
			<div className="flex justify-between items-center p-4">
				<Link href="/?stay=true" aria-label="Go to home">
					<Image
						src="/omnibin-logo.webp"
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
			{shouldShowPopupA && <PopupA />}
		</>
	);
}
