import type { ReactNode } from "react";
import { HomeLogo } from "@/components/home-logo";
import { cn } from "@/lib/utils";

export function SiteHeader({
  className,
  children,
}: {
  className?: string;
  children?: ReactNode;
}) {
  return (
    <header
      className={cn(
        "mx-auto flex h-[72px] w-full items-center justify-between px-4",
        className
      )}
    >
      <HomeLogo />
      <div className="flex items-center gap-1">{children}</div>
    </header>
  );
}
