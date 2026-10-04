/// <reference types="astro/client" />
/// <reference path="../.cloudflare/types/index.d.ts" />
import type { APIContext } from "astro";
import type { SessionData as AuthSessionData } from "@auth0/auth0-server-js";
import type { createAuth0 } from "./lib/auth0";
import type { createPrisma } from "./lib/prisma";
declare global {
  namespace App {
    interface Locals {
      auth0: ReturnType<typeof createAuth0>;
      authContext: APIContext;
      getSession: () => Promise<AuthSessionData | undefined>;
      getPrisma: () => ReturnType<typeof createPrisma>;
    }
  }
}
