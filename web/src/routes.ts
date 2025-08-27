export const OMNIBIN_ROUTES = {
	BIN: "/bin",
	LOGIN: "/auth/login",
	LOGOUT: "/auth/logout",
};

export const OMNIBIN_API_ROUTES = {
	BIN: "/api/bin",
	BIN_ITEM: getBilledInvoicesDataRoute,
};

function getBilledInvoicesDataRoute({ itemId }: { itemId: string }) {
	return `/api/bin/${itemId}`;
}
