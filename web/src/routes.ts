export const OMNIBIN_ROUTES = {
	BIN: "/api/bin",
};

export const OMNIBIN_API_ROUTES = {
	BIN_ITEM: getBilledInvoicesDataRoute,
};

function getBilledInvoicesDataRoute({ itemId }: { itemId: string }) {
	return `/api/bin/${itemId}`;
}
