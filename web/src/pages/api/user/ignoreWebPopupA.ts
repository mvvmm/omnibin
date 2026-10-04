import type { APIContext } from "astro";

import { authenticateRequest } from "@/lib/auth0";

export async function PATCH({ request: req, locals }: APIContext) {
  const prisma = locals.getPrisma();
  try {
    const payload = await authenticateRequest(req, locals);
    const auth0Sub = payload.sub;

    const user = await prisma.user.findUnique({
      where: { auth0Id: auth0Sub },
      select: { id: true },
    });

    if (!user) {
      return Response.json({ error: "User not found" }, { status: 404 });
    }

    await prisma.user.update({
      where: { id: user.id },
      data: {
        ignoreWebPopupA: true,
      },
    });

    return Response.json({ success: true });
  } catch (error) {
    const typed = error as Error & { statusCode?: number };
    console.error("Error in PATCH /api/user/ignoreWebPopupA:", typed.message);
    return Response.json(
      { error: typed.message },
      { status: typed.statusCode ?? 500 }
    );
  }
}
