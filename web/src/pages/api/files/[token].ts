import { env } from "cloudflare:workers";
import type { APIContext } from "astro";

import { MAX_FILE_SIZE } from "@/constants/constants";
import { verifyFileToken } from "@/lib/file-token";

function error(status: number, message: string) {
  return Response.json(
    { error: message },
    { status, headers: { "Cache-Control": "private, no-store" } }
  );
}

export async function PUT({ request, params }: APIContext) {
  const token = await verifyFileToken(params.token ?? "", "put");
  if (!token) return error(403, "Invalid or expired upload URL");

  if (request.headers.get("content-type") !== token.contentType) {
    return error(400, "Content-Type does not match the upload");
  }
  const lengthHeader = request.headers.get("content-length");
  if (lengthHeader === null) return error(411, "Content-Length is required");
  const length = Number(lengthHeader);
  if (length !== token.size || length > MAX_FILE_SIZE) {
    return error(413, "Content-Length does not match the upload");
  }
  if (!request.body) return error(400, "Missing file body");

  await env.FILES.put(token.key, request.body, {
    httpMetadata: { contentType: token.contentType },
  });
  return new Response(null, { status: 200 });
}

export async function GET({ request, params }: APIContext) {
  const token = await verifyFileToken(params.token ?? "", "get");
  if (!token) return error(403, "Invalid or expired file URL");

  const object = await env.FILES.get(token.key, {
    range: request.headers,
    onlyIf: request.headers,
  });
  if (!object) return error(404, "File not found");

  const headers = new Headers();
  object.writeHttpMetadata(headers);
  if (!headers.has("content-type")) {
    headers.set("Content-Type", token.contentType);
  }
  headers.set("ETag", object.httpEtag);
  headers.set("Accept-Ranges", "bytes");
  headers.set("Cache-Control", "private, max-age=3600");

  if (!("body" in object)) {
    const status = request.headers.has("if-none-match") ? 304 : 412;
    return new Response(null, { status, headers });
  }

  if (request.headers.has("range") && object.range) {
    const range = object.range as {
      offset?: number;
      length?: number;
      suffix?: number;
    };
    const offset =
      range.suffix !== undefined
        ? object.size - range.suffix
        : (range.offset ?? 0);
    const length = range.length ?? object.size - offset;
    headers.set(
      "Content-Range",
      `bytes ${offset}-${offset + length - 1}/${object.size}`
    );
    headers.set("Content-Length", String(length));
    return new Response(object.body, { status: 206, headers });
  }

  headers.set("Content-Length", String(object.size));
  return new Response(object.body, { headers });
}
