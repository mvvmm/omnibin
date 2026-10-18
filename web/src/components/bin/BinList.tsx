import type { BinItem } from "@/types/bin";
import { BinListItem } from "./BinListItem";
export function BinList({ items }: { items: BinItem[] }) {
  if (!items.length)
    return (
      <p className="py-12 text-center text-sm text-muted-foreground">
        Nothing here yet. Paste something above.
      </p>
    );
  return (
    <ul className="space-y-2">
      {items.map((item) => (
        <BinListItem key={item.id} item={item} />
      ))}
    </ul>
  );
}
