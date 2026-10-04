import { defineMiddleware } from "astro:middleware";
import { createAuth0 } from "./lib/auth0";
import { createPrisma } from "./lib/prisma";
export const onRequest = defineMiddleware(async (context, next) => {
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
  try {
    const response = await next();
    if (
      context.url.pathname.startsWith("/api/") ||
      context.url.pathname.startsWith("/auth/") ||
      context.url.pathname === "/bin" ||
      response.headers.has("Set-Cookie") ||
      !context.url.pathname.includes(".")
    )
      response.headers.set("Cache-Control", "private, no-store");
    return response;
  } finally {
    if (prisma) await prisma.$disconnect();
  }
});
