import { createRemoteJWKSet, jwtVerify } from "jose";
import { env } from "cloudflare:workers";
import { httpError } from "./auth0";
export async function verifyAccessToken(header?: string) {
  const match = header?.match(/^Bearer ([^ ]+)$/i);
  if (!match) throw httpError(401, "Missing or invalid Authorization header");
  const issuer =
    new URL(
      env.AUTH0_DOMAIN.startsWith("http")
        ? env.AUTH0_DOMAIN
        : `https://${env.AUTH0_DOMAIN}`
    ).origin + "/";
  try {
    const { payload } = await jwtVerify(
      match[1],
      createRemoteJWKSet(new URL(".well-known/jwks.json", issuer)),
      { issuer, audience: env.AUTH0_AUDIENCE, algorithms: ["RS256"] }
    );
    if (!payload.sub) throw new Error("Missing subject");
    return { ...payload, sub: payload.sub };
  } catch {
    throw httpError(401, "Invalid access token");
  }
}
