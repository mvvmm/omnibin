import { randomBytes } from "node:crypto";
import { appendFileSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";

// Builds currently consumes this output format even when cf performs the deployment.
// https://github.com/cloudflare/cf/issues/185
export function writePreviewOutput(
  stdout,
  workerName,
  environment = process.env
) {
  const file =
    environment.WRANGLER_OUTPUT_FILE_PATH ||
    (environment.WRANGLER_OUTPUT_FILE_DIRECTORY &&
      resolve(
        environment.WRANGLER_OUTPUT_FILE_DIRECTORY,
        `wrangler-output-${new Date().toISOString().replaceAll(":", "-").replace(".", "_").replace("T", "_").replace("Z", "")}-${randomBytes(3).toString("hex")}.json`
      ));
  if (!file) return;
  const clean = stdout.replace(/\x1b\[[0-9;]*m/g, "");
  const result = JSON.parse(
    clean.slice(clean.indexOf("{"), clean.lastIndexOf("}") + 1)
  );
  if (result.type !== "preview" || !result.preview_urls)
    throw new Error("cf did not return a Preview deployment result");
  mkdirSync(dirname(file), { recursive: true });
  appendFileSync(
    file,
    `${JSON.stringify({ ...result, worker_name: workerName, timestamp: new Date().toISOString() })}\n`
  );
  return file;
}
