import * as React from "react";
import { cn } from "@/lib/utils";

export interface ButtonProps
	extends React.ButtonHTMLAttributes<HTMLButtonElement> {}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
	({ className, ...props }, ref) => {
		return (
			<button
				ref={ref}
				className={cn(
					"inline-flex items-center justify-center rounded-xl px-6 py-3 text-base font-semibold transition-transform duration-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-white/60",
					className,
				)}
				{...props}
			/>
		);
	},
);
Button.displayName = "Button";
