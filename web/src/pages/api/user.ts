import type { APIContext } from "astro";

import { authenticateRequest } from "@/lib/auth0";

export async function GET({ request: req, locals }: APIContext) {
  const prisma = locals.getPrisma();
  try {
    const payload = await authenticateRequest(req, locals);
    const auth0Sub = payload.sub;

    const user = await prisma.user.upsert({
      where: { auth0Id: auth0Sub },
      update: {},
      create: { auth0Id: auth0Sub },
      select: {
        id: true,
        ignoreWebPopupA: true,
      },
    });

    return Response.json({ user });
  } catch (error) {
    const typed = error as Error & { statusCode?: number };
    console.error("Error in GET /api/user:", typed.message);
    return Response.json(
      { error: typed.message },
      { status: typed.statusCode ?? 401 }
    );
  }
}
