import test from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, readdirSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { writePreviewOutput } from "../scripts/preview-output.mjs";
const result = {
  type: "preview",
  version: 1,
  preview_urls: ["https://preview.example"],
  deployment_id: "test-id",
};
test("preview output is discoverable by Workers Builds", () => {
  const dir = mkdtempSync(join(tmpdir(), "omnibin-output-"));
  try {
    const file = writePreviewOutput(
      `\x1b[32m${JSON.stringify(result, null, 2)}\x1b[0m\n`,
      "omnibin",
      { WRANGLER_OUTPUT_FILE_DIRECTORY: dir }
    );
    assert.match(file, /wrangler-output-.*\.json$/);
    const entry = JSON.parse(readFileSync(file, "utf8"));
    assert.deepEqual(entry.preview_urls, result.preview_urls);
    assert.equal(entry.worker_name, "omnibin");
    assert.equal(entry.deployment_id, "test-id");
    assert.ok(Date.parse(entry.timestamp));
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
test("explicit output file wins and results append as JSON lines", () => {
  const dir = mkdtempSync(join(tmpdir(), "omnibin-output-"));
  try {
    const file = join(dir, "nested", "output.json");
    for (let i = 0; i < 2; i++)
      writePreviewOutput(JSON.stringify(result), "omnibin", {
        WRANGLER_OUTPUT_FILE_PATH: file,
        WRANGLER_OUTPUT_FILE_DIRECTORY: join(dir, "unused"),
      });
    assert.equal(readFileSync(file, "utf8").trim().split("\n").length, 2);
    assert.deepEqual(readdirSync(dir), ["nested"]);
    assert.throws(
      () =>
        writePreviewOutput("{}", "omnibin", {
          WRANGLER_OUTPUT_FILE_PATH: file,
        }),
      /Preview deployment result/
    );
    assert.equal(readFileSync(file, "utf8").trim().split("\n").length, 2);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
test("local deployments do not require a Builds output file", () => {
  assert.equal(writePreviewOutput("not json", "omnibin", {}), undefined);
});
