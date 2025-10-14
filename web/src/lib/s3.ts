import {
	DeleteObjectCommand,
	GetObjectCommand,
	PutObjectCommand,
	S3Client,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { awsCredentialsProvider } from "@vercel/functions/oidc";
import { S3_URL_EXPIRATION_SECONDS } from "@/constants/constants";

const region = process.env.AWS_REGION;
const bucket = process.env.S3_BUCKET;
const roleArn = process.env.AWS_ROLE_ARN;
const isVercel = process.env.VERCEL === "1";

if (!region) throw new Error("Missing AWS_REGION env var");
if (!bucket) throw new Error("Missing S3_BUCKET env var");

export const s3 = new S3Client({
	region,
	// On Vercel, use OIDC credentials via role; locally fall back to default provider chain
	credentials:
		isVercel && roleArn ? awsCredentialsProvider({ roleArn }) : undefined,
});

export async function createPresignedPutUrl(params: {
	key: string;
	contentType: string;
	expiresInSeconds?: number;
}) {
	const { key, contentType, expiresInSeconds = 60 } = params;
	const cmd = new PutObjectCommand({
		Bucket: bucket,
		Key: key,
		ContentType: contentType,
	});
	const url = await getSignedUrl(s3, cmd, { expiresIn: expiresInSeconds });
	return url;
}

export async function createPresignedGetUrl(params: {
	key: string;
	expiresInSeconds?: number;
}) {
	const { key, expiresInSeconds = S3_URL_EXPIRATION_SECONDS } = params;
	const cmd = new GetObjectCommand({ Bucket: bucket, Key: key });
	const url = await getSignedUrl(s3, cmd, { expiresIn: expiresInSeconds });
	return url;
}

export async function deleteObjectByKey(key: string) {
	await s3.send(new DeleteObjectCommand({ Bucket: bucket, Key: key }));
}

export function getBucketName(): string {
	if (!bucket) throw new Error("Missing S3_BUCKET env var");
	return bucket;
}
