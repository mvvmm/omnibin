import { Skeleton } from "@/components/ui/skeleton";

export default function BinListLoading() {
  return (
    <ul className="space-y-2">
      {[1, 2, 3].map((i) => (
        <li key={i} className="overflow-hidden rounded-lg border bg-card">
          <div className="flex items-center gap-2 py-1.5 pr-1.5 pl-4">
            <Skeleton className="h-4 flex-1" />
            <Skeleton className="m-2 size-6" />
            <Skeleton className="m-2 size-6" />
          </div>
          {i === 2 && <Skeleton className="aspect-video w-full rounded-none" />}
        </li>
      ))}
    </ul>
  );
}
