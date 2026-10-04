import type { APIRoute } from "astro";
export const GET: APIRoute = async ({ locals, url, redirect }) => {
  try {
    await locals.auth0.completeInteractiveLogin(url, locals.authContext);
    return redirect("/bin");
  } catch {
    return new Response("Unable to complete login. Please try again.", {
      status: 400,
    });
  }
};
