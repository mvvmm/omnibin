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
test("file routes reject invalid tokens", options, async () => {
  const forged = `${Buffer.from(
    JSON.stringify({
      op: "get",
      key: "user/file",
      contentType: "text/plain",
      exp: 9999999999,
    })
  ).toString("base64url")}.invalid`;
  for (const token of ["missing", forged]) {
    const get = await fetch(new URL(`/api/files/${token}`, origin));
    assert.equal(get.status, 403, token);
    assert.equal(get.headers.get("cache-control"), "private, no-store");
    const put = await fetch(new URL(`/api/files/${token}`, origin), {
      method: "PUT",
      headers: { "Content-Type": "text/plain" },
      body: "x",
    });
    assert.equal(put.status, 403, token);
  }
});
test(
  "cross-site form submissions are rejected outside file routes",
  options,
  async () => {
    for (const contentType of [
      "text/plain",
      "application/x-www-form-urlencoded",
      "multipart/form-data; boundary=x",
    ]) {
      const response = await fetch(new URL("/api/bin", origin), {
        method: "POST",
        headers: {
          Origin: "https://untrusted.example",
          "Content-Type": contentType,
        },
        body: "x",
      });
      assert.equal(response.status, 403, contentType);
      assert.match(await response.text(), /Cross-site POST form submissions/);
    }
    const upload = await fetch(new URL("/api/files/invalid", origin), {
      method: "PUT",
      headers: { "Content-Type": "text/plain" },
      body: "x",
    });
    assert.equal(upload.status, 403);
    assert.match(await upload.text(), /Invalid or expired upload URL/);
  }
);
