import test from "node:test";
import assert from "node:assert/strict";
import {
  StatelessStateStore,
  CookieTransactionStore,
} from "@auth0/auth0-server-js";
import { cookieHandler } from "../src/lib/auth0-cookies.ts";
function context() {
  const data = new Map();
  const options = new Map();
  return {
    data,
    options,
    url: new URL("https://app.example"),
    request: new Request("https://app.example"),
    cookies: {
      set(name, value, opts) {
        data.set(name, value);
        options.set(name, opts);
      },
      get(name) {
        return data.has(name) ? { value: data.get(name) } : undefined;
      },
      delete(name) {
        data.delete(name);
      },
    },
    sync() {
      this.request = new Request(this.url, {
        headers: {
          cookie: [...data]
            .map(([name, value]) => `${name}=${value}`)
            .join("; "),
        },
      });
    },
  };
}
test("Astro cookie adapter round-trips encrypted chunked sessions and clears logout cookies", async () => {
  const ctx = context();
  const store = new StatelessStateStore(
    { secret: "a".repeat(64) },
    cookieHandler
  );
  const now = Math.floor(Date.now() / 1000);
  const state = {
    user: { sub: "auth0|test", name: "a".repeat(6000) },
    tokenSets: [],
    internal: { createdAt: now },
  };
  await store.set("__a0_session", state, false, ctx);
  ctx.sync();
  assert.ok(ctx.data.size > 1);
  for (const opts of ctx.options.values()) {
    assert.equal(opts.httpOnly, true);
    assert.equal(opts.secure, true);
    assert.equal(opts.sameSite, "lax");
    assert.equal(opts.path, "/");
  }
  assert.equal((await store.get("__a0_session", ctx)).user.sub, "auth0|test");
  const [name, value] = [...ctx.data][0];
  ctx.data.set(name, `broken${value}`);
  ctx.sync();
  assert.equal(await store.get("__a0_session", ctx), undefined);
  await store.delete("__a0_session", ctx);
  assert.equal(ctx.data.size, 0);
});
test("OAuth transaction cookie works in local development and remains HttpOnly", async () => {
  const ctx = context();
  ctx.url = new URL("http://localhost:3000");
  const store = new CookieTransactionStore(
    { secret: "b".repeat(64) },
    cookieHandler
  );
  await store.set(
    "__a0_tx",
    { state: "test-state", codeVerifier: "test-verifier" },
    false,
    ctx
  );
  ctx.sync();
  assert.equal((await store.get("__a0_tx", ctx)).state, "test-state");
  for (const opts of ctx.options.values()) {
    assert.equal(opts.secure, false);
    assert.equal(opts.httpOnly, true);
  }
  await store.delete("__a0_tx", ctx);
  assert.equal(ctx.data.size, 0);
});
