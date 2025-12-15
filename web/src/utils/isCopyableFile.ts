export const isCopyableFile = (contentType: string): boolean => {
  const supportedMimeTypes = [
    "image/png",
    "image/jpeg",
    "image/jpg",
    "image/gif",
    "image/webp",
    "image/svg+xml",
    "text/plain",
    "text/html",
    // "application/json",
    // "application/pdf",
  ];
  return supportedMimeTypes.includes(contentType);
};
