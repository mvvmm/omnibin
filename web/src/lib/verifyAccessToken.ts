import type { JWTPayload } from "jose";
import { createRemoteJWKSet, jwtVerify } from "jose";

const issuer = process.env.AUTH0_DOMAIN;
const audience = process.env.AUTH0_AUDIENCE;

console.log("🔧 Auth0 Config - Issuer:", issuer, "Audience:", audience);

if (!issuer) throw new Error("Missing AUTH0_ISSUER_BASE_URL env var");
if (!audience) throw new Error("Missing AUTH0_AUDIENCE env var");

const jwks = createRemoteJWKSet(new URL(`${issuer}.well-known/jwks.json`));

export type VerifiedToken = JWTPayload & { sub: string };

export async function verifyAccessToken(
	authorizationHeader?: string,
): Promise<VerifiedToken> {
	console.log(
		"🔍 verifyAccessToken called with header:",
		authorizationHeader?.substring(0, 50) + "...",
	);

	const token = extractBearer(authorizationHeader);
	console.log(
		"🔍 Extracted token:",
		token ? token.substring(0, 50) + "..." : "null",
	);

	if (!token) {
		console.log("❌ No token found in authorization header");
		throw createHttpError(401, "Missing or invalid Authorization header");
	}

	console.log("🔍 Verifying token with issuer:", issuer, "audience:", audience);

	try {
		const { payload } = await jwtVerify(token, jwks, {
			issuer,
			audience,
		});

		console.log("✅ Token verified successfully, payload:", {
			sub: payload.sub,
			aud: payload.aud,
			iss: payload.iss,
			exp: payload.exp,
		});

		if (!payload.sub) throw createHttpError(401, "Token missing subject (sub)");
		return payload as VerifiedToken;
	} catch (error) {
		console.log("❌ Token verification failed:", error);
		throw error;
	}
}

function extractBearer(header?: string): string | undefined {
	if (!header) return undefined;
	const [scheme, token] = header.split(" ");
	if (scheme?.toLowerCase() !== "bearer" || !token) return undefined;
	return token;
}

type HttpError = Error & { statusCode: number };
function createHttpError(statusCode: number, message: string): HttpError {
	const err = new Error(message) as HttpError;
	err.statusCode = statusCode;
	return err;
}
