// vite.config.ts: one small plugin inlines sebaro's icon sprite and the sign tile into index.html (ICO-04: the sprite
// sits once inline at the top of the body), in dev and in the build, straight from the copied export in
// public/sebaro/ (never edited). Everything else is plain Vite.
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { defineConfig, type Plugin } from "vite";

const exportFile = (p: string) => readFileSync(fileURLToPath(new URL(`./public/sebaro/${p}`, import.meta.url)), "utf8").trim();

function sebaroInline(): Plugin {
  return {
    name: "sebaro-inline",
    transformIndexHtml(html) {
      return html
        .replace(/<!-- sebaro:sprite[^>]*-->/, () => exportFile("icons/sprite.svg"))
        .replace("<!-- sebaro:tile-32 -->", () => exportFile("brand/inline/tile-studio-small.svg"))
        .replace("<!-- sebaro:tile-48 -->", () => exportFile("brand/inline/tile-studio.svg"));
    },
  };
}

export default defineConfig({
  plugins: [sebaroInline()],
  build: {
    // no inline module preload helper in the page (the CSP allows no inline script)
    modulePreload: { polyfill: false },
  },
});
