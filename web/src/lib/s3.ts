import {
  DeleteObjectCommand,
  GetObjectCommand,
  PutObjectCommand,
  S3Client,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { env } from "cloudflare:workers";
import { S3_URL_EXPIRATION_SECONDS } from "@/constants/constants";

function getS3() {
  return new S3Client({
    region: env.AWS_REGION,
    credentials: {
      accessKeyId: env.AWS_ACCESS_KEY_ID,
      secretAccessKey: env.AWS_SECRET_ACCESS_KEY,
    },
  });
}

export async function createPresignedPutUrl(params: {
  key: string;
  contentType: string;
  expiresInSeconds?: number;
}) {
  const { key, contentType, expiresInSeconds = 60 } = params;
  const cmd = new PutObjectCommand({
    Bucket: env.S3_BUCKET,
    Key: key,
    ContentType: contentType,
  });
  const url = await getSignedUrl(getS3(), cmd, { expiresIn: expiresInSeconds });
  return url;
}

export async function createPresignedGetUrl(params: {
  key: string;
  expiresInSeconds?: number;
}) {
  const { key, expiresInSeconds = S3_URL_EXPIRATION_SECONDS } = params;
  const cmd = new GetObjectCommand({ Bucket: env.S3_BUCKET, Key: key });
  const url = await getSignedUrl(getS3(), cmd, { expiresIn: expiresInSeconds });
  return url;
}

export async function deleteObjectByKey(key: string) {
  await getS3().send(
    new DeleteObjectCommand({ Bucket: env.S3_BUCKET, Key: key })
  );
}

export function getBucketName(): string {
  if (!env.S3_BUCKET) throw new Error("Missing S3_BUCKET env var");
  return env.S3_BUCKET;
}
