import type { APIContext } from "astro";
import type { CookieHandler } from "@auth0/auth0-server-js";
export const cookieHandler: CookieHandler<APIContext> = {
  setCookie(name, value, options, context) {
    context!.cookies.set(name, value, {
      ...options,
      httpOnly: true,
      path: "/",
      secure: context!.url.protocol === "https:",
    });
  },
  getCookie(name, context) {
    return context!.cookies.get(name)?.value;
  },
  getCookies(context) {
    return Object.fromEntries(
      (context!.request.headers.get("cookie") ?? "")
        .split(";")
        .filter((part) => part.includes("="))
        .map((part) => {
          const name = part.trim().split("=")[0];
          return [name, context!.cookies.get(name)?.value ?? ""];
        })
    );
  },
  deleteCookie(name, context, options) {
    context!.cookies.delete(name, { ...options, path: "/" });
  },
};
