/**
 * IMPORTANT: This value must be kept in sync with:
 * - iOS: apple/omnibin/omnibin Share Extension/ShareViewController.swift (maxSize)
 * - Backend validation in this file is the source of truth
 */
export const MAX_FILE_SIZE = 50 * 1024 * 1024; // 50MB
export const MAX_CHAR_LIMIT = 10000;
export const BIN_ITEMS_LIMIT = 10;
export const CACHE_DURATION_SECONDS = 300; // 5 minutes
export const S3_URL_EXPIRATION_SECONDS = 3600; // 60 minutes
export const ALWAYS_SHOW_POPUP_A = false;
