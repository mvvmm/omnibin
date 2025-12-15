import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";

export const metadata: Metadata = {
  title: "About",
  description:
    "Learn about omnibin - a cross-platform clipboard sync tool built to make sharing content with yourself effortless. Available on iOS and web.",
  alternates: {
    canonical: `${process.env.NEXT_PUBLIC_BASE_URL || "https://omnib.in"}/about`,
  },
};

const APP_STORE_URL = "https://apps.apple.com/nl/app/omnibin/id6752793228";
const SUPPORT_URL = "https://omnib.in/support";
const WEB_URL = "https://omnib.in";
const VANCE_GITHUB_URL = "https://github.com/mvvmm";

export default function AboutPage() {
  return (
    <div className="relative z-10 mx-auto max-w-3xl px-4 py-12 sm:px-6 lg:px-8">
      <Card className="mx-auto w-full p-8 md:p-12 glass">
        <CardHeader className="px-0">
          <div className="flex items-center justify-center mb-4">
            <Image
              src="/binboy.png"
              alt="binboy logo"
              width={450}
              height={450}
              priority
              className="h-auto w-auto"
            />
          </div>
          <CardTitle className="text-3xl">About</CardTitle>
          <CardDescription className="text-base">
            Learn more about omnibin
          </CardDescription>
        </CardHeader>
        <CardContent className="px-0">
          <div className="space-y-8">
            <section className="space-y-3">
              <h2
                className="text-xl font-semibold"
                style={{ color: "var(--foreground)" }}
              >
                Why omnibin exists
              </h2>
              <p className="text-sm" style={{ color: "var(--muted-80)" }}>
                omnibin was born from frustration with the existing tools for
                sharing content between your own devices. Emailing yourself or
                uploading to Google Drive requires too many steps and isn&apos;t
                designed for this use case. OneDrive and similar services try to
                do everything, which makes the simple act of moving content from
                one device to another unnecessarily complicated.
              </p>
              <p className="text-sm" style={{ color: "var(--muted-80)" }}>
                Most software that offers self-sharing treats it as a secondary
                feature, which means it&apos;s often inefficient and clunky. I
                wanted to build a tool where sharing content with yourself is
                the primary focus. Every feature in omnibin is designed around
                making this experience as seamless and efficient as possible.
              </p>
            </section>

            <section className="space-y-3">
              <h2
                className="text-xl font-semibold"
                style={{ color: "var(--foreground)" }}
              >
                Platform availability
              </h2>
              <p className="text-sm" style={{ color: "var(--muted-80)" }}>
                omnibin is currently available on iOS through the{" "}
                <Link
                  href={APP_STORE_URL}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="underline"
                >
                  App Store
                </Link>{" "}
                and on the{" "}
                <Link href={WEB_URL} className="underline">
                  web
                </Link>{" "}
                for all other devices. I&apos;m actively exploring which
                platform to support next, with a focus on fully leveraging each
                platform&apos;s native features. The goal is to make copy,
                paste, and sharing as efficient as possible on every device,
                which means deep integration with platform-specific capabilities
                rather than a one-size-fits-all approach.
              </p>
            </section>

            <section className="space-y-3">
              <h2
                className="text-xl font-semibold"
                style={{ color: "var(--foreground)" }}
              >
                Help improve omnibin
              </h2>
              <p className="text-sm" style={{ color: "var(--muted-80)" }}>
                Have a feature request or found a bug? Visit our{" "}
                <Link href={SUPPORT_URL} className="underline">
                  support page
                </Link>{" "}
                to submit feedback or report issues.
              </p>
            </section>
          </div>
          <div className="mt-8 pt-6 border-t">
            <p
              className="text-xs text-center"
              style={{ color: "var(--muted-80)" }}
            >
              omnibin was built by{" "}
              <Link
                href={VANCE_GITHUB_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="underline"
              >
                mvm
              </Link>
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
