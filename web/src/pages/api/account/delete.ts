import { env } from "cloudflare:workers";
import { ManagementClient } from "auth0";
import type { APIContext } from "astro";

import { deleteObjectByKey } from "@/lib/s3";
import { authenticateRequest } from "@/lib/auth0";

export async function DELETE({ request: req, locals }: APIContext) {
  const prisma = locals.getPrisma();
  // Initialize Auth0 Management API client
  const management = new ManagementClient({
    domain: env.AUTH0_MANAGEMENT_DOMAIN || "",
    clientId: env.AUTH0_MANAGEMENT_CLIENT_ID || "",
    clientSecret: env.AUTH0_MANAGEMENT_CLIENT_SECRET || "",
  });

  try {
    // Validate required environment variables
    if (
      !env.AUTH0_DOMAIN ||
      !env.AUTH0_MANAGEMENT_CLIENT_ID ||
      !env.AUTH0_MANAGEMENT_CLIENT_SECRET
    ) {
      console.error("❌ Missing required environment variables");
      return Response.json(
        { error: "Server configuration error" },
        { status: 500 }
      );
    }

    // Verify the user's access token
    const payload = await authenticateRequest(req, locals);
    const auth0Sub = payload.sub;

    // Find the user in our database
    const user = await prisma.user.findUnique({
      where: { auth0Id: auth0Sub },
      select: { id: true },
    });

    if (!user) {
      console.error("❌ User not found in database");
      return Response.json({ error: "User not found" }, { status: 404 });
    }

    // Get all user's bin items with their file items for S3 cleanup
    const userBinItems = await prisma.binItem.findMany({
      where: { userId: user.id },
      include: { fileItem: true },
    });

    // Delete all files from S3 storage
    const fileKeys = userBinItems
      .map((item) => item.fileItem?.key)
      .filter((key): key is string => Boolean(key));

    // Delete files from S3 in parallel
    if (fileKeys.length > 0) {
      await Promise.all(
        fileKeys.map((key) =>
          deleteObjectByKey(key).catch((error) => {
            console.error(`❌ Failed to delete S3 object ${key}:`, error);
            // Continue with deletion even if S3 cleanup fails
          })
        )
      );
    }

    // Delete all user data from database
    // The cascade relationships will handle TextItem and FileItem deletion
    await prisma.user.delete({
      where: { id: user.id },
    });

    // Delete the user from Auth0
    await management.users.delete(auth0Sub);

    return Response.json(
      {
        message: "Account and all data successfully deleted",
      },
      { status: 200 }
    );
  } catch (error) {
    const typed = error as Error & { statusCode?: number };
    console.error("❌ Account deletion failed:", typed.message);
    console.error("❌ Error details:", error);

    // If it's an Auth0 error, provide more specific messaging
    if (typed.message.includes("auth0") || typed.message.includes("Auth0")) {
      console.error("❌ Auth0-specific error occurred");
      return Response.json(
        { error: "Failed to delete Auth0 account. Please contact support." },
        { status: 500 }
      );
    }

    console.error("❌ Returning error response to client");
    return Response.json(
      { error: typed.message || "Failed to delete account" },
      { status: typed.statusCode ?? 500 }
    );
  }
}
