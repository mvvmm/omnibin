import type { ImgHTMLAttributes } from "react";
type Props = ImgHTMLAttributes<HTMLImageElement> & {
  fill?: boolean;
  priority?: boolean;
  quality?: number;
  unoptimized?: boolean;
};
export default function Image({
  fill,
  priority,
  quality: _quality,
  unoptimized: _unoptimized,
  style,
  ...props
}: Props) {
  return (
    <img
      {...props}
      loading={priority ? "eager" : (props.loading ?? "lazy")}
      fetchPriority={priority ? "high" : undefined}
      style={
        fill
          ? {
              position: "absolute",
              inset: 0,
              width: "100%",
              height: "100%",
              ...style,
            }
          : style
      }
    />
  );
}
