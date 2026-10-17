# omnibin web

Astro 7.4 beta, React 19, and Cloudflare Workers. Data is stored in Cloudflare D1 through Prisma and files in Cloudflare R2. Auth0 is retained. The API paths and bearer-token authentication used by iOS are unchanged.

Use Node 22.18 or later and pnpm 10.22. Run commands from `web/`:

```sh
pnpm install --frozen-lockfile
# Create .env with the service secrets declared in cloudflare.config.ts.
pnpm run types
pnpm run db:migrate:local
pnpm run dev
```

`cf dev` runs Astro with the Worker runtime at http://localhost:3000. `cloudflare.config.ts` defines the Worker, bindings, compatibility settings, and observability. No Wrangler CLI or Wrangler configuration is used; cf's internal deployment dependencies may still include Wrangler.

```sh
pnpm run check
pnpm test
pnpm run build
pnpm run deploy
pnpm run deploy:preview
```

`cf deploy` and `cf previews deploy` build before uploading. `pnpm test` runs cookie-adapter tests. To include HTTP tests against a running local Worker or a deployment:

```sh
TEST_ORIGIN=http://localhost:3000 pnpm test
```

## Runtime services

Web API requests use encrypted, chunked HttpOnly Auth0 session cookies. The Auth0 server SDK handles OAuth transactions, PKCE, token refresh, and session expiry. Mutations authenticated by cookies require a matching Origin header. An explicit Authorization header is always verified as an Auth0 bearer token, preserving mobile authentication. Authentication callbacks and logout use the current request origin, so previews never redirect to the production app.

Prisma uses `engineType = "client"` and the D1 adapter over the `DB` binding (database `omnibin`). Production and previews share it. `prisma/schema.prisma` is the source of truth; D1 migrations are SQL files in `migrations/`, tracked by `cf d1 migrations`.

| Task                                             | Command                     |
| ------------------------------------------------ | --------------------------- |
| Apply migrations to local D1                     | `pnpm run db:migrate:local` |
| Print SQL for schema changes not yet in local D1 | `pnpm run db:diff`          |
| Apply migrations to production D1                | `pnpm run db:migrate`       |

To change the schema, edit `prisma/schema.prisma`, save `pnpm run -s db:diff` output as the next numbered file in `migrations/`, and run `pnpm run db:migrate:local`. `pnpm run deploy` applies pending migrations before deploying production; Preview deploys never migrate because they share the production database. Apply an additive migration with `pnpm run db:migrate` first if a Preview must exercise it.

`pnpm run dev` uses simulated local D1 and R2 in `.cloudflare/state`. `pnpm run dev:remote` connects both bindings to the production database and bucket, so every local write is a production write.

Files are stored in the R2 bucket `omnibin-private` through the `FILES` binding; production and previews share it, as they share the database. `POST /api/bin` and `GET /api/bin/:id` return `/api/files/<token>` URLs on the request origin. Tokens are HMAC-signed with `FILE_TOKEN_SECRET` and bind the object key, content type, size (uploads), and expiry: 60 seconds for uploads and one hour for downloads. The route streams uploads into R2 and serves downloads with range and ETag support. It authenticates only by token, so it is exempt from the cross-origin form check in `src/middleware.ts`, which otherwise mirrors Astro's `checkOrigin`.

Runtime secrets are declared in `cloudflare.config.ts`. For the first deployment, cf requires a secrets file:

```sh
pnpm exec cf deploy --secrets-file /path/to/secrets.json
```

Subsequent builds reuse stored Worker secrets. Runtime secrets do not need to be exposed as build environment variables.

## Workers Builds and Previews

The Cloudflare account is connected to `mvvmm/omnibin`. Production watches `main`; previews build other branches. Both use:

| Setting                   | Value                                           |
| ------------------------- | ----------------------------------------------- |
| Root directory            | `/web`                                          |
| Build command             | `pnpm run types && pnpm run check && pnpm test` |
| Production deploy command | `pnpm run deploy`                               |
| Preview deploy command    | `pnpm run deploy:preview`                       |
| Included paths            | `web/**`                                        |

The deploy scripts build the application, so the Builds build command performs validation first. Builds uses the existing Cloudflare deployment token reference. Preview Base secrets are configured separately from production and copied into new previews. The migration preview was also populated explicitly. `cloudflare.config.ts` declares secrets with `bindings.secret()` for all builds. cf preserves secrets from the previous Preview deployment automatically; new Previews receive Preview Base secrets. No CLI patch or explicit `unsafe:inherit` bindings are required. Previews use the production D1 database and R2 bucket; changing Preview Base secrets does not update existing previews.

`pnpm run deploy:preview` runs `cf previews deploy` directly. `cf` beta.18 writes the Preview result, including `worker_name` and `timestamp`, to the Workers Builds output file itself ([cloudflare/cf#185](https://github.com/cloudflare/cf/issues/185)). No output wrapper is needed.

## Review URLs and domain cutover

- Worker: https://omnibin.root-mvm.workers.dev
- Migration preview: https://feat-astro-cloudflare-omnibin.root-mvm.workers.dev

Auth0 must allow the stable origin's `/auth/callback` URL and logout origin. Preview callback URLs can use `https://*-omnibin.root-mvm.workers.dev/auth/callback`, with `https://*-omnibin.root-mvm.workers.dev` for preview logout URLs. The stable Worker Auth0 URLs and preview wildcards were added during migration. File URLs are same-origin, so storage needs no CORS rules.

Production uses the Worker custom domains `omnib.in` and `www.omnib.in`, with DNS hosted by Cloudflare and registration retained at Squarespace. Previews use their default Workers preview URLs and do not claim production domains. Existing web sessions require login again because the Auth0 session implementation changed. Signed file URLs use standard browser images rather than Next's image optimization endpoint.
