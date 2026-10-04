import { bindings, defineConfig } from "cf/config";
import * as entrypoint from "@astrojs/cloudflare/entrypoints/server" with { type: "cf-worker" };

export default defineConfig({
  worker: {
    name: "omnibin",
    compatibilityDate: "2026-10-03",
    compatibilityFlags: ["nodejs_compat", "global_fetch_strictly_public"],
    entrypoint,
    workersDev: true,
    env: {
      ASSETS: bindings.assets(),
      DATABASE_URL: bindings.secret(),
      AUTH0_DOMAIN: bindings.secret(),
      AUTH0_CLIENT_ID: bindings.secret(),
      AUTH0_CLIENT_SECRET: bindings.secret(),
      AUTH0_SECRET: bindings.secret(),
      AUTH0_AUDIENCE: bindings.secret(),
      AUTH0_SCOPE: bindings.secret(),
      AUTH0_SESSION_INACTIVITY_DURATION: bindings.secret(),
      AUTH0_SESSION_ABSOLUTE_DURATION: bindings.secret(),
      AUTH0_MANAGEMENT_DOMAIN: bindings.secret(),
      AUTH0_MANAGEMENT_CLIENT_ID: bindings.secret(),
      AUTH0_MANAGEMENT_CLIENT_SECRET: bindings.secret(),
      AWS_REGION: bindings.secret(),
      S3_BUCKET: bindings.secret(),
      AWS_ACCESS_KEY_ID: bindings.secret(),
      AWS_SECRET_ACCESS_KEY: bindings.secret(),
    },
    observability: {
      enabled: true,
      logs: { enabled: true },
      traces: { enabled: true },
    },
  },
});
