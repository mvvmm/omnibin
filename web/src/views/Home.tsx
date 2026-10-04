import { ArrowRight, LogIn } from "lucide-react";
import Image from "@/components/image";
import Link from "@/components/link";
import { ContextMenu } from "@/components/context-menu";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";

export default function Home({ loggedIn }: { loggedIn: boolean }) {
  return (
    <>
      <div className="flex justify-end p-4">
        <ContextMenu loggedIn={loggedIn} />
      </div>

      <div className="relative z-10 mx-auto flex max-w-6xl items-center justify-center px-4 pb-8 sm:px-6 lg:px-8">
        <Card className="mx-auto w-full max-w-3xl p-8 text-center md:p-12 glass bg-accent/10 !gap-0">
          <div className="flex items-center justify-center">
            <Image
              src="/omnibin-logo.webp"
              alt="omnibin logo"
              width={680}
              height={170}
              priority={true}
              loading="eager"
              quality={50}
              className="h-auto w-full max-w-[720px]"
            />
          </div>

          <h1 className="mt-8 font-comfortaa text-4xl font-semibold tracking-tight sm:text-5xl md:text-6xl text-foreground">
            Copy. Paste. Anywhere.
          </h1>
          <p
            className="mx-auto mt-4 max-w-2xl text-balance text-base sm:text-lg"
            style={{ color: "var(--muted-80)" }}
          >
            Seamless cross‑platform clipboard. Move text, images, and files
            between devices with ease.
          </p>

          <div className="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row sm:gap-4">
            <Button asChild className="btn-omnibin">
              <Link href="/bin">
                {loggedIn ? "Go to shared bin" : "Login to sync"}
                {loggedIn ? (
                  <ArrowRight className="ml-2 h-5 w-5" aria-hidden="true" />
                ) : (
                  <LogIn className="ml-2 h-5 w-5" aria-hidden="true" />
                )}
              </Link>
            </Button>
          </div>

          <div className="mt-10 grid grid-cols-1 gap-4 text-left sm:grid-cols-3">
            <Card className="rounded-xl shadow-none p-4 text-foreground glass">
              <p className="text-sm">Cross-platform</p>
              <p className="mt-1 text-xs" style={{ color: "var(--muted-60)" }}>
                Share one bin on all devices.
              </p>
            </Card>
            <Card
              className="rounded-xl shadow-none p-4 glass"
              style={{
                color: "var(--foreground)",
              }}
            >
              <p className="text-sm">Effortless</p>
              <p className="mt-1 text-xs" style={{ color: "var(--muted-60)" }}>
                One click copy and paste.
              </p>
            </Card>
            <Card
              className="rounded-xl shadow-none p-4 glass"
              style={{
                color: "var(--foreground)",
              }}
            >
              <p className="text-sm">Fast, secure sync</p>
              <p className="mt-1 text-xs" style={{ color: "var(--muted-60)" }}>
                Backed by modern auth and storage.
              </p>
            </Card>
          </div>
        </Card>
      </div>
    </>
  );
}
