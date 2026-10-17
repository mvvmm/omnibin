import { env } from "cloudflare:workers";

export type FileTokenPayload = {
  op: "put" | "get";
  key: string;
  contentType: string;
  size?: number;
  exp: number;
};

const encoder = new TextEncoder();
let hmacKey: Promise<CryptoKey> | undefined;

function getHmacKey() {
  if (!env.FILE_TOKEN_SECRET) throw new Error("Missing FILE_TOKEN_SECRET");
  return (hmacKey ??= crypto.subtle.importKey(
    "raw",
    encoder.encode(env.FILE_TOKEN_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"]
  ));
}

function toBase64Url(bytes: Uint8Array) {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

function fromBase64Url(value: string) {
  const binary = atob(value.replace(/-/g, "+").replace(/_/g, "/"));
  return Uint8Array.from(binary, (c) => c.charCodeAt(0));
}

export async function signFileToken(payload: FileTokenPayload) {
  const body = toBase64Url(encoder.encode(JSON.stringify(payload)));
  const signature = await crypto.subtle.sign(
    "HMAC",
    await getHmacKey(),
    encoder.encode(body)
  );
  return `${body}.${toBase64Url(new Uint8Array(signature))}`;
}

export async function verifyFileToken(
  token: string,
  op: FileTokenPayload["op"]
): Promise<FileTokenPayload | null> {
  const [body, signature, extra] = token.split(".");
  if (!body || !signature || extra !== undefined) return null;
  try {
    const valid = await crypto.subtle.verify(
      "HMAC",
      await getHmacKey(),
      fromBase64Url(signature),
      encoder.encode(body)
    );
    if (!valid) return null;
    const payload = JSON.parse(
      new TextDecoder().decode(fromBase64Url(body))
    ) as FileTokenPayload;
    if (payload.op !== op || payload.exp < Date.now() / 1000) return null;
    return payload;
  } catch {
    return null;
  }
}
