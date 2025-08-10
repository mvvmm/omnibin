# @omnibin/db

Shared Prisma schema and client for the Omnibin PostgreSQL database.

## Environment

Create a `.env` file in `db/` with:

```
DATABASE_URL="postgresql://USER:PASSWORD@HOST:5432/omnibin?schema=public"
```

## Commands

- Generate client: `pnpm --filter @omnibin/db prisma:generate`
- Dev migrate (creates migration files): `pnpm --filter @omnibin/db prisma:migrate -- --name init`
- Deploy migrations (CI/prod): `pnpm --filter @omnibin/db prisma:deploy`
- Push (schema sync without migration files, dev only): `pnpm --filter @omnibin/db prisma:push`
- Studio: `pnpm --filter @omnibin/db prisma:studio`

## Consuming from apps

From any Node app in this repo, import the client:

```ts
import { prisma } from "@omnibin/db";
```

Ensure the app’s runtime environment defines `DATABASE_URL`.


