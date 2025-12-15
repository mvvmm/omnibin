import type { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
  const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || "https://omnib.in";

  return {
    rules: {
      userAgent: "*",
      allow: "/",
      disallow: ["/api/", "/bin"], // Disallow API routes and private bin pages
    },
    sitemap: `${baseUrl}/sitemap.xml`,
  };
}
