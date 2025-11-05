import { Button } from "../ui/button";
import { Skeleton } from "../ui/skeleton";
import { Textarea } from "../ui/textarea";

export default async function CreateItemFormLoading() {
	return (
		<form className="space-y-2">
			<div className="mb-4">
				<Textarea
					disabled
					placeholder="Loading..."
					rows={3}
					className="mb-1 transition-all duration-200 bg-red-500 glass"
				/>
			</div>

			<div className="flex items-end gap-3 justify-between">
				<Button disabled type="button" className="btn-omnibin">
					Loading...
				</Button>

				<div className="flex flex-col items-end col-gap-1 mr-1">
					<Skeleton className="w-16 h-4" />
				</div>
			</div>
		</form>
	);
}
