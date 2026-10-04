import { bindings, defineConfig } from "cf/config";
import * as entrypoint from "@astrojs/cloudflare/entrypoints/server" with { type: "cf-worker" };

export default defineConfig(({ isPreview }) => {
  // Preview uploads must explicitly retain secrets already stored on the Preview.
  const secret = () =>
    isPreview ? { type: "unsafe:inherit" as const } : bindings.secret();
  return {
    worker: {
      name: "omnibin",
      compatibilityDate: "2026-10-03",
      compatibilityFlags: ["nodejs_compat", "global_fetch_strictly_public"],
      entrypoint,
      workersDev: true,
      env: {
        ASSETS: bindings.assets(),
        DATABASE_URL: secret(),
        AUTH0_DOMAIN: secret(),
        AUTH0_CLIENT_ID: secret(),
        AUTH0_CLIENT_SECRET: secret(),
        AUTH0_SECRET: secret(),
        AUTH0_AUDIENCE: secret(),
        AUTH0_SCOPE: secret(),
        AUTH0_SESSION_INACTIVITY_DURATION: secret(),
        AUTH0_SESSION_ABSOLUTE_DURATION: secret(),
        AUTH0_MANAGEMENT_DOMAIN: secret(),
        AUTH0_MANAGEMENT_CLIENT_ID: secret(),
        AUTH0_MANAGEMENT_CLIENT_SECRET: secret(),
        AWS_REGION: secret(),
        S3_BUCKET: secret(),
        AWS_ACCESS_KEY_ID: secret(),
        AWS_SECRET_ACCESS_KEY: secret(),
      },
      observability: {
        enabled: true,
        logs: { enabled: true },
        traces: { enabled: true },
      },
    },
  };
});
