import Image from "@/components/image";
import Link from "@/components/link";

export function HomeLogo() {
  return (
    <Link
      href="/?stay=true"
      aria-label="Go to home"
      className="flex items-center gap-2 rounded-md text-[15px] font-semibold tracking-[-0.01em] text-foreground"
    >
      <Image
        src="/icon.png"
        alt=""
        width={26}
        height={26}
        className="size-[26px]"
        priority
      />
      omnibin
    </Link>
  );
}
