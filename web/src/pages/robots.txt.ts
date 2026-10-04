import type { APIRoute } from "astro";
export const GET: APIRoute = ({ url }) =>
  new Response(
    url.hostname === "omnib.in"
      ? "User-agent: *\nAllow: /\nDisallow: /api/\nDisallow: /bin\nSitemap: https://omnib.in/sitemap.xml\n"
      : "User-agent: *\nDisallow: /\n",
    { headers: { "Content-Type": "text/plain" } }
  );
