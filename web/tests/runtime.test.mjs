import test from "node:test";
import assert from "node:assert/strict";
const origin = process.env.TEST_ORIGIN;
const options = { skip: !origin };
test("public pages and metadata render", options, async () => {
  for (const path of [
    "/",
    "/about",
    "/support",
    "/privacy-policy",
    "/sitemap.xml",
    "/robots.txt",
  ]) {
    const response = await fetch(new URL(path, origin));
    assert.equal(response.status, 200, path);
    const body = await response.text();
    assert.ok(body.length > 20);
    if (path === "/") {
      assert.match(body, /Copy\. Paste\. Anywhere\./);
      assert.doesNotMatch(body, /\/\_next\//);
      assert.equal(response.headers.get("cache-control"), "private, no-store");
    }
  }
});
test(
  "private routes reject unauthenticated and invalid bearer requests",
  options,
  async () => {
    const bin = await fetch(new URL("/bin", origin), { redirect: "manual" });
    assert.equal(bin.status, 302);
    assert.equal(bin.headers.get("location"), "/auth/login");
    for (const path of ["/api/bin", "/api/user", "/api/bin/missing"]) {
      const response = await fetch(new URL(path, origin));
      assert.equal(response.status, 401, path);
      assert.equal(response.headers.get("cache-control"), "private, no-store");
      const invalid = await fetch(new URL(path, origin), {
        headers: { Authorization: "Bearer invalid" },
      });
      assert.equal(invalid.status, 401);
    }
  }
);
test("cookie mutations reject cross-origin requests", options, async () => {
  for (const [path, method] of [
    ["/api/bin", "POST"],
    ["/api/bin/missing", "DELETE"],
    ["/api/user/ignoreWebPopupA", "PATCH"],
    ["/api/account/delete", "DELETE"],
    ["/api/og", "POST"],
  ]) {
    const response = await fetch(new URL(path, origin), {
      method,
      headers: {
        Origin: "https://untrusted.example",
        "Content-Type": "application/json",
      },
      body: "{}",
    });
    assert.equal(response.status, 403, path);
  }
});
test("invalid auth callback fails safely", options, async () => {
  const response = await fetch(
    new URL("/auth/callback?code=invalid&state=invalid", origin),
    { redirect: "manual" }
  );
  assert.equal(response.status, 400);
});

test(
  "logout clears the session and uses the wildcard-compatible Auth0 endpoint",
  options,
  async () => {
    const response = await fetch(new URL("/auth/logout", origin), {
      redirect: "manual",
    });
    assert.equal(response.status, 302);
    const location = new URL(response.headers.get("location"));
    assert.equal(location.pathname, "/v2/logout");
    assert.equal(location.searchParams.get("returnTo"), new URL(origin).origin);
    assert.ok(location.searchParams.get("client_id"));
    assert.match(
      response.headers.get("set-cookie"),
      /__a0_session=.*Max-Age=0/i
    );
    if (new URL(origin).protocol === "https:") {
      const logout = await fetch(location, { redirect: "manual" });
      assert.equal(logout.status, 302);
      assert.equal(
        new URL(logout.headers.get("location")).origin,
        new URL(origin).origin
      );
    }
  }
);
