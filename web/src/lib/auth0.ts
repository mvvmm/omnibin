import { Auth0Client } from "@auth0/nextjs-auth0/server";
import { redirect } from "next/navigation";

// Initialize the Auth0 client
export const auth0 = new Auth0Client({
	signInReturnToPath: "/bin",
	authorizationParameters: {
		audience: process.env.AUTH0_AUDIENCE,
		scope: process.env.AUTH0_SCOPE,
	},
});

export async function getAccessTokenOrReauth(): Promise<string> {
	try {
		const { token } = await auth0.getAccessToken();
		return token;
	} catch (_error) {
		redirect("/api/auth/login");
	}
}
