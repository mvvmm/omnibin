/*
  Warnings:

  - You are about to drop the column `content` on the `BinItem` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[textItemId]` on the table `BinItem` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[fileItemId]` on the table `BinItem` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateEnum
CREATE TYPE "public"."BinItemKind" AS ENUM ('TEXT', 'FILE');

-- CreateEnum
CREATE TYPE "public"."StorageProvider" AS ENUM ('S3');

-- AlterTable
ALTER TABLE "public"."BinItem" DROP COLUMN "content",
ADD COLUMN     "fileItemId" TEXT,
ADD COLUMN     "kind" "public"."BinItemKind" NOT NULL DEFAULT 'TEXT',
ADD COLUMN     "textItemId" TEXT;

-- CreateTable
CREATE TABLE "public"."TextItem" (
    "id" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "TextItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."FileItem" (
    "id" TEXT NOT NULL,
    "provider" "public"."StorageProvider" NOT NULL DEFAULT 'S3',
    "bucket" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "originalName" TEXT NOT NULL,
    "contentType" TEXT NOT NULL,
    "size" BIGINT NOT NULL,
    "checksum" TEXT,
    "preview" TEXT,
    "expiresAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "FileItem_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "FileItem_bucket_key_key" ON "public"."FileItem"("bucket", "key");

-- CreateIndex
CREATE UNIQUE INDEX "BinItem_textItemId_key" ON "public"."BinItem"("textItemId");

-- CreateIndex
CREATE UNIQUE INDEX "BinItem_fileItemId_key" ON "public"."BinItem"("fileItemId");

-- AddForeignKey
ALTER TABLE "public"."BinItem" ADD CONSTRAINT "BinItem_textItemId_fkey" FOREIGN KEY ("textItemId") REFERENCES "public"."TextItem"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."BinItem" ADD CONSTRAINT "BinItem_fileItemId_fkey" FOREIGN KEY ("fileItemId") REFERENCES "public"."FileItem"("id") ON DELETE CASCADE ON UPDATE CASCADE;
