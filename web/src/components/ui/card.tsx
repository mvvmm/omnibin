import * as React from "react";
import { cn } from "@/lib/utils";

export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {}

export const Card = React.forwardRef<HTMLDivElement, CardProps>(
	({ className, ...props }, ref) => (
		<div
			ref={ref}
			className={cn(
				"rounded-3xl border shadow-2xl backdrop-blur-xl",
				className,
			)}
			{...props}
		/>
	),
);
Card.displayName = "Card";

export const CardHeader = React.forwardRef<HTMLDivElement, CardProps>(
	({ className, ...props }, ref) => (
		<div ref={ref} className={cn("p-6", className)} {...props} />
	),
);
CardHeader.displayName = "CardHeader";

export const CardTitle = React.forwardRef<
	HTMLHeadingElement,
	React.HTMLAttributes<HTMLHeadingElement>
>(({ className, ...props }, ref) => (
	<h3
		ref={ref}
		className={cn(
			"text-2xl font-semibold leading-none tracking-tight",
			className,
		)}
		{...props}
	/>
));
CardTitle.displayName = "CardTitle";

export const CardContent = React.forwardRef<HTMLDivElement, CardProps>(
	({ className, ...props }, ref) => (
		<div ref={ref} className={cn("p-6", className)} {...props} />
	),
);
CardContent.displayName = "CardContent";
