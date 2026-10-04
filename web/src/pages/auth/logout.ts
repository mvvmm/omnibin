import type { APIRoute } from "astro";
export const GET: APIRoute = async ({ locals, redirect }) => {
  const url = await locals.auth0.logout(
    { returnTo: locals.authContext.url.origin },
    locals.authContext
  );
  return redirect(url.href);
};
