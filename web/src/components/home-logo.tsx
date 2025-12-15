import Image from "next/image";
import Link from "next/link";

interface HomeLogoProps {
  className?: string;
}

export function HomeLogo({ className }: HomeLogoProps) {
  return (
    <Link href="/?stay=true" aria-label="Go to home">
      <div className="glass rounded-lg px-3 py-2 transition-transform duration-300 hover:scale-[1.02]">
        <Image
          src="/omnibin-logo.webp"
          alt="omnibin logo"
          width={340}
          height={100}
          className={className ?? "h-8 w-auto"}
          priority
        />
      </div>
    </Link>
  );
}
