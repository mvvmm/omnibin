import Image from "next/image";

export default function Loading() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center">
      <div className="relative w-48 animate-grow">
        {/* Glassy/transparent base - grayscale */}
        <Image
          src="/binboy.png"
          alt="binboy logo"
          width={200}
          height={200}
          priority
          className="h-auto w-48"
          style={{
            filter: "grayscale(100%) opacity(0.15) blur(2px)",
          }}
        />
        {/* Colored fill overlay */}
        <div
          className="absolute top-0 left-0 w-full h-full overflow-hidden animate-fill-up"
          style={{ clipPath: "inset(100% 0% 0% 0%)" }}
        >
          <Image
            src="/binboy.png"
            alt="binboy logo"
            width={200}
            height={200}
            priority
            className="h-auto w-48"
          />
        </div>
      </div>
    </div>
  );
}
