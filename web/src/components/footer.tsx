import Link from "@/components/link";

const linkClassName =
  "px-2.5 py-3 text-muted-foreground transition-colors hover:text-foreground";

export function Footer() {
  return (
    <footer className="border-t">
      <div className="mx-auto flex max-w-5xl flex-wrap items-center justify-between gap-x-4 gap-y-2 px-4 py-2 text-[13px] text-muted-foreground">
        <div>
          © {new Date().getFullYear()}{" "}
          <a
            href="https://github.com/mvvmm"
            target="_blank"
            rel="noopener noreferrer"
            className="transition-colors hover:text-foreground"
          >
            mvm
          </a>
        </div>
        <nav className="-mx-2.5 flex flex-wrap">
          <Link href="/about" className={linkClassName}>
            About
          </Link>
          <Link href="/privacy-policy" className={linkClassName}>
            Privacy Policy
          </Link>
          <Link href="/support" className={linkClassName}>
            Support
          </Link>
          <a
            href="https://github.com/mvvmm/omnibin"
            target="_blank"
            rel="noopener noreferrer"
            className={linkClassName}
          >
            GitHub
          </a>
          <a
            href="https://apps.apple.com/us/app/omnibin/id6752793228"
            target="_blank"
            rel="noopener noreferrer"
            className={linkClassName}
          >
            iOS App
          </a>
        </nav>
      </div>
    </footer>
  );
}
