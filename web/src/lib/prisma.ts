import { PrismaClient } from "@prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";
import { env } from "cloudflare:workers";
// A pool belongs to one request; middleware closes it after the response is rendered.
export function createPrisma() {
  return new PrismaClient({
    adapter: new PrismaPg({ connectionString: env.DATABASE_URL, max: 1 }),
    log: ["error"],
  });
}
