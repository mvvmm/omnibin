import {
  CookieTransactionStore,
  ServerClient,
  StatelessStateStore,
} from "@auth0/auth0-server-js";
import type { APIContext } from "astro";
import { env } from "cloudflare:workers";
import { cookieHandler } from "./auth0-cookies";
import { verifyAccessToken } from "./verifyAccessToken";

export function createAuth0(context: APIContext) {
  const secret = env.AUTH0_SECRET;
  return new ServerClient<APIContext>({
    domain: new URL(
      env.AUTH0_DOMAIN.startsWith("http")
        ? env.AUTH0_DOMAIN
        : `https://${env.AUTH0_DOMAIN}`
    ).hostname,
    clientId: env.AUTH0_CLIENT_ID,
    clientSecret: env.AUTH0_CLIENT_SECRET,
    authorizationParams: {
      redirect_uri: new URL("/auth/callback", context.url.origin).href,
      audience: env.AUTH0_AUDIENCE,
      scope: env.AUTH0_SCOPE || "openid profile email offline_access",
    },
    transactionStore: new CookieTransactionStore({ secret }, cookieHandler),
    stateStore: new StatelessStateStore(
      {
        secret,
        rolling: true,
        inactivityDuration:
          Number(env.AUTH0_SESSION_INACTIVITY_DURATION) || 86400,
        absoluteDuration: Number(env.AUTH0_SESSION_ABSOLUTE_DURATION) || 259200,
        cookie: {
          sameSite: "lax",
          secure: context.url.protocol === "https:",
          path: "/",
        },
      },
      cookieHandler
    ),
  });
}
export function httpError(statusCode: number, message: string) {
  return Object.assign(new Error(message), { statusCode });
}
export async function authenticateRequest(
  request: Request,
  locals: App.Locals
) {
  // An explicit bearer header is authoritative, including when a browser session exists.
  const authorization = request.headers.get("authorization");
  if (authorization) return verifyAccessToken(authorization);
  if (
    !["GET", "HEAD", "OPTIONS"].includes(request.method) &&
    request.headers.get("origin") !== new URL(request.url).origin
  )
    throw httpError(403, "Invalid request origin");
  const session = await locals.getSession();
  if (!session?.user?.sub) throw httpError(401, "Authentication required");
  try {
    await locals.auth0.getAccessToken({}, locals.authContext);
  } catch {
    throw httpError(401, "Please log in again");
  }
  return { sub: session.user.sub };
}
