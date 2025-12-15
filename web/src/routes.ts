export const OMNIBIN_ROUTES = {
  BIN: "/bin",
  LOGIN: "/auth/login",
  LOGOUT: "/auth/logout",
};

export const OMNIBIN_API_ROUTES = {
  BIN: "/api/bin",
  OG: "/api/og",
  BIN_ITEM: getBinItemRoute,
  ACCOUNT_DELETE: "/api/account/delete",
  USER: "/api/user",
  DISMISS_WEB_POPUP_A: "/api/user/ignoreWebPopupA",
};

function getBinItemRoute({ itemId }: { itemId: string }) {
  return `/api/bin/${itemId}`;
}
