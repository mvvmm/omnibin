import { defineMiddleware } from "astro:middleware";
import { createAuth0 } from "./lib/auth0";
import { createPrisma } from "./lib/prisma";

const FORM_CONTENT_TYPES = [
  "application/x-www-form-urlencoded",
  "multipart/form-data",
  "text/plain",
];
const SAFE_METHODS = ["GET", "HEAD", "OPTIONS"];

// Mirrors Astro's checkOrigin, minus /api/files/: those URLs carry a signed token instead of cookies, and iOS uploads send no Origin.
function isForbiddenCrossOriginRequest(request: Request, url: URL) {
  if (SAFE_METHODS.includes(request.method)) return false;
  if (url.pathname.startsWith("/api/files/")) return false;
  if (request.headers.get("origin") === url.origin) return false;
  const contentType = request.headers.get("content-type");
  if (contentType === null) return true;
  const normalized = contentType.toLowerCase();
  return FORM_CONTENT_TYPES.some((type) => normalized.includes(type));
}

export const onRequest = defineMiddleware(async (context, next) => {
  if (isForbiddenCrossOriginRequest(context.request, context.url)) {
    return new Response(
      `Cross-site ${context.request.method} form submissions are forbidden`,
      { status: 403 }
    );
  }
  let auth0: ReturnType<typeof createAuth0> | undefined;
  Object.defineProperty(context.locals, "auth0", {
    get: () => (auth0 ??= createAuth0(context)),
  });
  context.locals.authContext = context;
  let session:
    | ReturnType<ReturnType<typeof createAuth0>["getSession"]>
    | undefined;
  context.locals.getSession = () =>
    (session ??= context.locals.auth0.getSession(context));
  let prisma: ReturnType<typeof createPrisma> | undefined;
  context.locals.getPrisma = () => (prisma ??= createPrisma());
  const response = await next();
  if (
    (context.url.pathname.startsWith("/api/") &&
      !context.url.pathname.startsWith("/api/files/")) ||
    context.url.pathname.startsWith("/auth/") ||
    context.url.pathname === "/bin" ||
    response.headers.has("Set-Cookie") ||
    !context.url.pathname.includes(".")
  )
    response.headers.set("Cache-Control", "private, no-store");
  return response;
});
