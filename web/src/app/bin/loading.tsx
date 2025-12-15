import BinListLoading from "@/components/bin/BinListLoading";
import CreateItemFormLoading from "@/components/bin/CreateItemFormLoading";

export default function Loading() {
  return (
    <div className="mx-auto flex max-w-6xl items-center justify-center px-4 py-12 sm:px-6 lg:px-8">
      <div className="mx-auto w-full max-w-3xl space-y-4">
        <h1 className="text-2xl font-semibold text-foreground">Your Bin</h1>
        <CreateItemFormLoading />
        <BinListLoading />
      </div>
    </div>
  );
}
