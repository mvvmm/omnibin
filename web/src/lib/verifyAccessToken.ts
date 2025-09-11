import type { JWTPayload } from "jose";
import { createRemoteJWKSet, jwtVerify } from "jose";

const issuer = process.env.AUTH0_DOMAIN;
const audience = process.env.AUTH0_AUDIENCE;

if (!issuer) throw new Error("Missing AUTH0_ISSUER_BASE_URL env var");
if (!audience) throw new Error("Missing AUTH0_AUDIENCE env var");

const jwks = createRemoteJWKSet(new URL(`${issuer}.well-known/jwks.json`));

export type VerifiedToken = JWTPayload & { sub: string };

export async function verifyAccessToken(
	authorizationHeader?: string,
): Promise<VerifiedToken> {
	const token = extractBearer(authorizationHeader);

	if (!token) {
		throw createHttpError(401, "Missing or invalid Authorization header");
	}

	try {
		const { payload } = await jwtVerify(token, jwks, {
			issuer,
			audience,
		});

		if (!payload.sub) throw createHttpError(401, "Token missing subject (sub)");
		return payload as VerifiedToken;
	} catch (error) {
		console.error("Token verification failed:", error);
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
