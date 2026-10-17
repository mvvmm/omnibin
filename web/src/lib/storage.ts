import { env } from "cloudflare:workers";
import {
  FILE_URL_EXPIRATION_SECONDS,
  FILES_BUCKET,
} from "@/constants/constants";
import { signFileToken } from "@/lib/file-token";

const UPLOAD_URL_EXPIRATION_SECONDS = 60;
const R2_DELETE_BATCH_SIZE = 1000;

function nowSeconds() {
  return Math.floor(Date.now() / 1000);
}

function fileUrl(origin: string, token: string) {
  return new URL(`/api/files/${token}`, origin).toString();
}

export async function createUploadUrl(params: {
  origin: string;
  key: string;
  contentType: string;
  size: number;
}) {
  const token = await signFileToken({
    op: "put",
    key: params.key,
    contentType: params.contentType,
    size: params.size,
    exp: nowSeconds() + UPLOAD_URL_EXPIRATION_SECONDS,
  });
  return fileUrl(params.origin, token);
}

export async function createDownloadUrl(params: {
  origin: string;
  key: string;
  contentType: string;
}) {
  const token = await signFileToken({
    op: "get",
    key: params.key,
    contentType: params.contentType,
    exp: nowSeconds() + FILE_URL_EXPIRATION_SECONDS,
  });
  return fileUrl(params.origin, token);
}

export async function deleteObjectByKey(key: string) {
  await env.FILES.delete(key);
}

export async function deleteObjectsByKeys(keys: string[]) {
  for (let i = 0; i < keys.length; i += R2_DELETE_BATCH_SIZE) {
    await env.FILES.delete(keys.slice(i, i + R2_DELETE_BATCH_SIZE));
  }
}

export function getBucketName(): string {
  return FILES_BUCKET;
}
