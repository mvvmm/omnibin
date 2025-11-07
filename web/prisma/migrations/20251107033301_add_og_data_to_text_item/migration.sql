-- AlterTable
ALTER TABLE "public"."TextItem" ADD COLUMN     "ogDataFetched" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "ogDescription" TEXT,
ADD COLUMN     "ogIcon" TEXT,
ADD COLUMN     "ogImage" TEXT,
ADD COLUMN     "ogImageHeight" INTEGER,
ADD COLUMN     "ogImageWidth" INTEGER,
ADD COLUMN     "ogSiteName" TEXT,
ADD COLUMN     "ogTitle" TEXT;
