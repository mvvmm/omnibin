import type { APIRoute } from "astro";
export const GET: APIRoute = async ({ locals, redirect }) => {
  const url = await locals.auth0.startInteractiveLogin({}, locals.authContext);
  return redirect(url.href);
};
