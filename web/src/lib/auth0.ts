import { Auth0Client } from "@auth0/nextjs-auth0/server";
import { redirect } from "next/navigation";
import { OMNIBIN_ROUTES } from "@/routes";

// Initialize the Auth0 client
export const auth0 = new Auth0Client({
	signInReturnToPath: "/bin",
	authorizationParameters: {
		audience: process.env.AUTH0_AUDIENCE,
		scope: process.env.AUTH0_SCOPE,
	},
	session: {
		rolling: true,
		inactivityDuration: Number(process.env.AUTH0_SESSION_INACTIVITY_DURATION),
		absoluteDuration: Number(process.env.AUTH0_SESSION_ABSOLUTE_DURATION),
	},
});

export async function getAccessTokenOrReauth(): Promise<string> {
	try {
		const { token } = await auth0.getAccessToken();
		return token;
	} catch (_error) {
		redirect(OMNIBIN_ROUTES.LOGIN);
	}
}

// Helper function to check if session is close to expiring
export async function isSessionNearExpiry(): Promise<boolean> {
	try {
		const session = await auth0.getSession();
		if (!session) return true;

		// Check if session expires within 7 days
		const sevenDaysFromNow = new Date();
		sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);

		return session.expiresAt && typeof session.expiresAt === "string"
			? new Date(session.expiresAt) < sevenDaysFromNow
			: true;
	} catch {
		return true;
	}
}
