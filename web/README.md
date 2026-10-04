# omnibin web

Astro 7.4 beta, React 19, and Cloudflare Workers. Supabase PostgreSQL, the existing Prisma schema, Auth0, and AWS S3 are retained. The API paths and bearer-token authentication used by iOS are unchanged.

Use Node 22.18 or later and pnpm 10.22. Run commands from `web/`:

```sh
pnpm install --frozen-lockfile
# Create .env with the service secrets declared in cloudflare.config.ts.
pnpm run types
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

`cf deploy` and `cf previews deploy` build before uploading. `pnpm test` runs cookie-adapter and preview-output tests. To include HTTP tests against a running local Worker or a deployment:

```sh
TEST_ORIGIN=http://localhost:3000 pnpm test
```

## Runtime services

Web API requests use encrypted, chunked HttpOnly Auth0 session cookies. The Auth0 server SDK handles OAuth transactions, PKCE, token refresh, and session expiry. Mutations authenticated by cookies require a matching Origin header. An explicit Authorization header is always verified as an Auth0 bearer token, preserving mobile authentication. Authentication callbacks and logout use the current request origin, so previews never redirect to the production app.

Prisma uses `engineType = "client"` and the PostgreSQL adapter. Each request creates a pool only when needed and closes it on completion. `DATABASE_URL` remains the Supabase connection; `DIRECT_DATABASE_URL` is needed only for migration commands. This migration does not change the database schema or run database migrations.

S3 credentials must be supplied as Worker secrets. Vercel's AWS OIDC role provider is removed. Use a dedicated AWS principal with the existing bucket's required object permissions. The existing local AWS credentials were used to bootstrap this Worker. Presigned uploads still go directly from the browser to S3.

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

The deploy scripts build the application, so the Builds build command performs validation first. Builds uses the existing Cloudflare deployment token reference. Preview Base secrets are configured separately from production and copied into new previews. The migration preview was also populated explicitly. For Preview builds, `cloudflare.config.ts` uses cf’s supported `unsafe:inherit` binding escape hatch to retain secrets from the previous deployment. Production and local development use `bindings.secret()`. No CLI patch is required. Previews currently use the existing Supabase database and S3 bucket; changing Preview Base secrets does not update existing previews.

`cf` beta.12 does not write its Preview result to the output file Workers Builds reads. `scripts/cf-previews-deploy.ts` runs cf, prints its result, then appends a Preview entry containing `worker_name` and `timestamp` to `WRANGLER_OUTPUT_FILE_PATH` or `WRANGLER_OUTPUT_FILE_DIRECTORY`. These are Cloudflare's output protocol variables; they do not invoke Wrangler. Remove the wrapper after [cloudflare/cf#185](https://github.com/cloudflare/cf/issues/185) is fixed and verified.

## Review URLs and domain cutover

- Worker: https://omnibin.root-mvm.workers.dev
- Migration preview: https://feat-astro-cloudflare-omnibin.root-mvm.workers.dev

Auth0 must allow the stable origin's `/auth/callback` URL and logout origin. Preview callback URLs can use `https://*-omnibin.root-mvm.workers.dev/auth/callback`, with `https://*-omnibin.root-mvm.workers.dev` for preview logout URLs. S3's upload CORS rules must allow the origins too. The stable Worker Auth0 URLs and preview wildcards were added during migration. S3 allows both URLs above; future preview origins need corresponding allowlist entries.

`omnib.in` remains on Vercel. No custom domain or DNS change is included. After review, the domain cutover will be performed separately by the owner. Existing web sessions will require login again because the Auth0 session implementation changed. Signed S3 images use standard browser images rather than Next's image optimization endpoint.
