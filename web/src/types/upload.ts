export type InitFileUploadResult =
	| { success: true; uploadUrl: string }
	| { success: false; error: string };
