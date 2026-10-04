export function GET() {
  return new Response(
    `<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">${["", "/about", "/support", "/privacy-policy"].map((path) => `<url><loc>https://omnib.in${path}</loc></url>`).join("")}</urlset>`,
    { headers: { "Content-Type": "application/xml" } }
  );
}
