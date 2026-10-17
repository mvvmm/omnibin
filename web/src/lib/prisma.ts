import { PrismaClient } from "@prisma/client";
import { PrismaD1 } from "@prisma/adapter-d1";
import { env } from "cloudflare:workers";

export function createPrisma() {
  return new PrismaClient({
    adapter: new PrismaD1(env.DB),
    log: ["error"],
  });
}
