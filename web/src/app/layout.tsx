import type { Metadata } from "next";
import "./globals.css";
import { Analytics } from "@vercel/analytics/next";
import { SpeedInsights } from "@vercel/speed-insights/next";
import { Footer } from "@/components/footer";
import { ThemeProvider } from "@/components/theme-provider";
import { Toaster } from "@/components/ui/sonner";
import { comfortaa, geistMono, geistSans } from "@/fonts";

export const metadata: Metadata = {
  title: {
    template: "omnibin • %s",
    default: "omnibin",
  },
  description:
    "Seamless cross-platform clipboard. Move text, images, and files between devices with ease. Copy. Paste. Anywhere.",
  authors: [{ name: "mvm" }],
  creator: "mvm",
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  metadataBase: new URL(process.env.NEXT_PUBLIC_BASE_URL || "https://omnib.in"),
  openGraph: {
    type: "website",
    locale: "en_US",
    siteName: "omnibin",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      suppressHydrationWarning
      lang="en"
      className={`${comfortaa.variable} ${geistSans.variable} ${geistMono.variable}`}
    >
      <body
        className="antialiased"
        style={{
          backgroundImage:
            "linear-gradient(to bottom right, var(--bg-from), var(--bg-via), var(--bg-to))",
        }}
      >
        <ThemeProvider>
          {/* Fixed background elements that cover the entire viewport */}
          <div className="fixed inset-0 pointer-events-none">
            {/* Mobile Blobs */}
            <div className="md:hidden absolute inset-0">
              {/* Mobile Blob 1 - Blue (Top Left) */}
              <div
                className="absolute blur-[60px] sm:blur-[100px]"
                style={{
                  backgroundColor: "var(--blob-5)",
                  opacity: "var(--blob-opacity)",
                  borderRadius: "70% 30% 50% 50% / 40% 60% 50% 60%",
                  left: "-20%",
                  width: "42rem",
                  height: "38rem",
                  transform: "translateY(-50%)",
                }}
              />

              {/* Mobile Blob 2 - Cyan (Middle Right) */}
              <div
                className="absolute blur-[60px] sm:blur-[100px]"
                style={{
                  backgroundColor: "var(--blob-6)",
                  opacity: "var(--blob-opacity)",
                  borderRadius: "50% 50% 40% 60% / 50% 50% 60% 40%",
                  bottom: "0%",
                  right: "-14%",
                  width: "42rem",
                  height: "32rem",
                  transform: "translateY(-50%)",
                }}
              />

              {/* Mobile Blob 3 - Pink (Bottom Center) */}
              <div
                className="absolute blur-[60px] sm:blur-[100px]"
                style={{
                  backgroundColor: "var(--blob-4)",
                  opacity: "var(--blob-opacity)",
                  bottom: "2%",
                  left: "-20%",
                  width: "34rem",
                  height: "42rem",
                  borderRadius: "40% 60% 50% 60% / 70% 30% 50% 50%",
                  transform: "translateY(50%)",
                }}
              />
            </div>

            {/* Desktop Blobs */}
            <div className="hidden md:block absolute inset-0">
              {/* Desktop Blob 1 - Top Left */}
              <div
                className="absolute blur-[200px]"
                style={{
                  backgroundColor: "var(--blob-1)",
                  opacity: "var(--blob-opacity)",
                  top: "-8%",
                  left: "-6%",
                  width: "44rem",
                  height: "38rem",
                  borderRadius: "60% 40% 30% 70% / 60% 30% 70% 40%",
                }}
              />

              {/* Desktop Blob 2 - Bottom Right */}
              <div
                className="absolute blur-[200px]"
                style={{
                  backgroundColor: "var(--blob-2)",
                  opacity: "var(--blob-opacity)",
                  bottom: "-12%",
                  right: "-8%",
                  width: "48rem",
                  height: "42rem",
                  borderRadius: "30% 60% 70% 40% / 50% 60% 30% 60%",
                }}
              />

              {/* Desktop Blob 3 - Top Center */}
              <div
                className="absolute blur-[200px]"
                style={{
                  backgroundColor: "var(--blob-3)",
                  opacity: "var(--blob-opacity)",
                  top: "-5%",
                  left: "42%",
                  width: "36rem",
                  height: "40rem",
                  borderRadius: "50% 50% 50% 50% / 60% 40% 60% 40%",
                }}
              />

              {/* Desktop Blob 4 - Bottom Center */}
              <div
                className="absolute blur-[200px]"
                style={{
                  backgroundColor: "var(--blob-4)",
                  opacity: "var(--blob-opacity)",
                  bottom: "-10%",
                  left: "48%",
                  width: "40rem",
                  height: "46rem",
                  borderRadius: "40% 60% 50% 60% / 70% 30% 50% 50%",
                }}
              />

              {/* Desktop Blob 5 - Bottom Left */}
              <div
                className="absolute blur-[200px]"
                style={{
                  backgroundColor: "var(--blob-5)",
                  opacity: "var(--blob-opacity)",
                  bottom: "-10%",
                  left: "-6%",
                  width: "38rem",
                  height: "44rem",
                  borderRadius: "70% 30% 50% 50% / 40% 60% 50% 60%",
                }}
              />

              {/* Desktop Blob 6 - Top Right */}
              <div
                className="absolute blur-[200px]"
                style={{
                  backgroundColor: "var(--blob-6)",
                  opacity: "var(--blob-opacity)",
                  top: "18%",
                  right: "-6%",
                  width: "42rem",
                  height: "34rem",
                  borderRadius: "50% 50% 40% 60% / 50% 50% 60% 40%",
                }}
              />
            </div>

            {/* Grid */}
            <div
              className="absolute inset-0 opacity-20 [mask-image:radial-gradient(60rem_60rem_at_center,white,transparent)]"
              style={{
                backgroundImage:
                  "linear-gradient(to right, var(--grid-line) 1px, transparent 1px), linear-gradient(to bottom, var(--grid-line) 1px, transparent 1px)",
                backgroundSize: "36px 36px",
              }}
            />
          </div>

          {/* Content container with relative positioning */}
          <div className="relative z-10 min-h-screen flex flex-col">
            <main className="flex-1">{children}</main>
            <Footer />
          </div>
          <Analytics />
          <SpeedInsights />
          <Toaster />
        </ThemeProvider>
      </body>
    </html>
  );
}
