import type { APIRoute } from "astro";
import { env } from "cloudflare:workers";
export const GET: APIRoute = async ({ locals, redirect }) => {
  const url = await locals.auth0.logout(
    { returnTo: locals.authContext.url.origin },
    locals.authContext
  );
  // Auth0's OIDC logout requires exact redirect URLs; /v2/logout supports preview wildcards.
  url.pathname = "/v2/logout";
  url.search = "";
  url.searchParams.set("client_id", env.AUTH0_CLIENT_ID);
  url.searchParams.set("returnTo", locals.authContext.url.origin);
  return redirect(url.href);
};
