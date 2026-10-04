import type { BinItem } from "@/types/bin";
import { BinListItem } from "./BinListItem";
export function BinList({ items }: { items: BinItem[] }) {
  if (!items.length)
    return <p className="text-muted-foreground">No items yet.</p>;
  return (
    <ul className="space-y-3">
      {items.map((item) => (
        <BinListItem key={item.id} item={item} />
      ))}
    </ul>
  );
}
