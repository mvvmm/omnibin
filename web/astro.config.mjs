import { defineConfig } from "astro/config";
import cloudflare from "@astrojs/cloudflare";
import react from "@astrojs/react";
import tailwindcss from "@tailwindcss/vite";
export default defineConfig({
  site: "https://omnib.in",
  output: "server",
  adapter: cloudflare({ imageService: "passthrough" }),
  session: false,
  vite: { plugins: [tailwindcss()] },
  integrations: [react()],
  server: { port: 3000 },
});
