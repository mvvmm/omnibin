import AppShell from "./AppShell";
import { ContextMenu } from "./context-menu";
import { HomeLogo } from "./home-logo";
import Home from "@/views/Home";
import About from "@/views/About";
import Support from "@/views/Support";
import PrivacyPolicy from "@/views/PrivacyPolicy";
import ImageGen from "@/views/ImageGen";
const pages = {
  about: About,
  support: Support,
  "privacy-policy": PrivacyPolicy,
  "image-gen": ImageGen,
};
export default function PageApp({
  page,
  loggedIn,
}: {
  page: "home" | keyof typeof pages;
  loggedIn: boolean;
}) {
  const Page = page === "home" ? undefined : pages[page];
  return (
    <AppShell>
      {Page ? (
        <>
          <div className="flex justify-between items-center p-4">
            <HomeLogo />
            <ContextMenu loggedIn={loggedIn} />
          </div>
          <Page />
        </>
      ) : (
        <Home loggedIn={loggedIn} />
      )}
    </AppShell>
  );
}
