import { execFileSync } from "node:child_process";
import { join } from "node:path";
import { writePreviewOutput } from "./preview-output.mjs";

// Remove this bridge once cf writes the Workers Builds result itself (cf issue #185).
const stdout = execFileSync(
  "pnpm",
  [
    "exec",
    "cf",
    "previews",
    "deploy",
    ...process.argv.slice(2).filter((arg) => arg !== "--"),
  ],
  {
    cwd: join(import.meta.dirname, ".."),
    encoding: "utf8",
    stdio: ["ignore", "pipe", "inherit"],
  }
);
process.stdout.write(stdout);
const file = writePreviewOutput(stdout, "omnibin");
if (file) console.log(`cf-previews-deploy: wrote the Preview entry to ${file}`);
