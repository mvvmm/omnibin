import Image from "@/components/image";
import { Card } from "@/components/ui/card";

export default function Page() {
  // portfolio cover image - 1000x600 with just binboy logo
  return (
    <div className="flex min-h-screen items-center justify-center p-4">
      {/* 1000x600 container */}
      <div className="relative" style={{ width: "1000px", height: "600px" }}>
        {/* Main card */}
        <Card className="relative z-10 flex h-full w-full items-center justify-center rounded-none glass">
          {/* Binboy Logo */}
          <div className="flex items-center justify-center">
            <Image
              src="/binboy.png"
              alt="binboy logo"
              width={1024}
              height={1024}
              priority
              style={{ width: "300px", height: "300px" }}
            />
          </div>
        </Card>
      </div>
    </div>
  );
}
