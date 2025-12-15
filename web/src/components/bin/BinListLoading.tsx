import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";

export default function BinListLoading() {
  return (
    <ul className="space-y-4">
      {[1, 2, 3].map((i) => (
        <li key={i}>
          <Card className="w-full p-3 text-foreground hover:scale-[101%] hover:cursor-pointer transition-transform !gap-0 glass">
            <div className="flex items-start justify-between gap-3">
              <div className="font-medium text-foreground flex-1 min-w-0 truncate">
                <Skeleton className="h-5 w-3/4" />
              </div>
              <div className="flex items-center gap-1.5">
                {[1, 2, 3].map((n) => (
                  <Skeleton key={n} className="h-8 w-8" />
                ))}
              </div>
            </div>

            <div className="flex items-start justify-start gap-3">
              <div className="min-w-0 flex-1 text-left">
                <div className="block mt-2 -mx-3 overflow-hidden">
                  <div className="relative w-full overflow-hidden">
                    <div
                      className="relative w-full overflow-hidden bg-muted/20"
                      style={{ aspectRatio: "16 / 9" }}
                    >
                      <Skeleton className="h-full w-full rounded-none dark:hidden" />
                    </div>

                    <div className="px-3 pt-3">
                      <Skeleton className="h-4 w-3/4 mb-2" />
                      <Skeleton className="h-3 w-[150px] mb-4" />
                      <Skeleton className="h-3 w-[250px]" />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </Card>
        </li>
      ))}
    </ul>
  );
}
