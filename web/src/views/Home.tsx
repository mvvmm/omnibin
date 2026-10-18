import Image from "@/components/image";
import Link from "@/components/link";
import { ContextMenu } from "@/components/context-menu";
import { SiteHeader } from "@/components/site-header";
import { Button } from "@/components/ui/button";
import { OMNIBIN_ROUTES } from "@/routes";

const APP_STORE_URL = "https://apps.apple.com/us/app/omnibin/id6752793228";

export default function Home({ loggedIn }: { loggedIn: boolean }) {
  return (
    <>
      <SiteHeader className="max-w-5xl">
        <ContextMenu loggedIn={loggedIn} />
        {!loggedIn && (
          <Button asChild variant="outline">
            <Link href={OMNIBIN_ROUTES.BIN}>Log in</Link>
          </Button>
        )}
      </SiteHeader>

      <section className="mx-auto flex w-full max-w-3xl flex-1 flex-col items-center justify-center gap-5 px-4 pt-16 pb-24 text-center">
        <Image
          src="/icon.png"
          alt="omnibin mascot"
          width={96}
          height={96}
          className="size-24"
          priority
        />
        <h1 className="text-5xl leading-[1.05] font-semibold tracking-[-0.035em] text-balance sm:text-[56px]">
          Copy. Paste. Anywhere.
        </h1>
        <p className="max-w-[520px] text-lg text-balance text-muted-foreground">
          A shared clipboard for all your devices. Move text, images, and files
          between them in one click.
        </p>
        <div className="mt-2 flex flex-wrap justify-center gap-2.5">
          <Button asChild size="lg" className="h-11 px-5 text-[15px]">
            <Link href={OMNIBIN_ROUTES.BIN}>
              {loggedIn ? "Go to your bin" : "Log in to sync"}
            </Link>
          </Button>
          <Button
            asChild
            size="lg"
            variant="outline"
            className="h-11 px-5 text-[15px]"
          >
            <a href={APP_STORE_URL} target="_blank" rel="noopener noreferrer">
              Get the iOS app
            </a>
          </Button>
        </div>
      </section>
    </>
  );
}
