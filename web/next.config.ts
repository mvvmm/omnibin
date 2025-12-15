import type { NextConfig } from "next";

const bucket = process.env.S3_BUCKET;
const region = process.env.AWS_REGION;
const s3Host =
  bucket && region ? `${bucket}.s3.${region}.amazonaws.com` : undefined;

const nextConfig: NextConfig = {
  images: {
    remotePatterns: s3Host
      ? [
          {
            protocol: "https",
            hostname: s3Host,
            pathname: "/**",
          },
        ]
      : [],
  },
};

export default nextConfig;
