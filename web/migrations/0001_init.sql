-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "auth0Id" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "ignoreWebPopupA" BOOLEAN NOT NULL DEFAULT false
);

-- CreateTable
CREATE TABLE "BinItem" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "kind" TEXT NOT NULL DEFAULT 'TEXT',
    "textItemId" TEXT,
    "fileItemId" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "BinItem_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "BinItem_textItemId_fkey" FOREIGN KEY ("textItemId") REFERENCES "TextItem" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "BinItem_fileItemId_fkey" FOREIGN KEY ("fileItemId") REFERENCES "FileItem" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "TextItem" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "content" TEXT NOT NULL,
    "ogDataFetched" BOOLEAN NOT NULL DEFAULT false,
    "ogTitle" TEXT,
    "ogDescription" TEXT,
    "ogImage" TEXT,
    "ogImageWidth" INTEGER,
    "ogImageHeight" INTEGER,
    "ogIcon" TEXT,
    "ogSiteName" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "FileItem" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "provider" TEXT NOT NULL DEFAULT 'R2',
    "bucket" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "originalName" TEXT NOT NULL,
    "contentType" TEXT NOT NULL,
    "size" BIGINT NOT NULL,
    "checksum" TEXT,
    "preview" TEXT,
    "imageWidth" INTEGER,
    "imageHeight" INTEGER,
    "expiresAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateIndex
CREATE UNIQUE INDEX "User_auth0Id_key" ON "User"("auth0Id");

-- CreateIndex
CREATE UNIQUE INDEX "BinItem_textItemId_key" ON "BinItem"("textItemId");

-- CreateIndex
CREATE UNIQUE INDEX "BinItem_fileItemId_key" ON "BinItem"("fileItemId");

-- CreateIndex
CREATE INDEX "BinItem_userId_idx" ON "BinItem"("userId");

-- CreateIndex
CREATE INDEX "BinItem_createdAt_idx" ON "BinItem"("createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "FileItem_bucket_key_key" ON "FileItem"("bucket", "key");

