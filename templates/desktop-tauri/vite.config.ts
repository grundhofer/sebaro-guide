// vite.config.ts: the webview's frontend. One small plugin fills index.html at build (and dev) time:
//   <!-- app:sprite -->   the export's icons/sprite.svg, inlined as it is (WEB-01, ICO-04)
//   <!-- app:tile -->     the sign tile of the title bar: brand/inline/tile-studio-small.svg, the generic umbrella tile
//                         as a placeholder; a real product puts its own tile from the workshop here (ZEI-03, ZEI-06)
//   {{key}}               a word from src/strings.ts (TEC-10), HTML-escaped
//   {{i:name}} {{i16:name}} {{irow:name}}   an icon from the sprite: 24 px, 16 px, or as the icon of an sb-row
// Everything stays a file or markup: no inline script, no style attribute, so the strict CSP holds (DSK-01).
import { defineConfig, type Plugin } from "vite";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { de } from "./src/strings.ts";

const root = import.meta.dirname;
const exportDir = resolve(root, "public/sebaro");

function escapeHtml(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}
function icon(name: string, extra: string): string {
  return `<svg class="sb-icon${extra}" aria-hidden="true" focusable="false"><use href="#${name}"/></svg>`;
}

function sebaroPage(): Plugin {
  return {
    name: "sebaro-page",
    transformIndexHtml(html) {
      const sprite = readFileSync(resolve(exportDir, "icons/sprite.svg"), "utf8");
      const tile = readFileSync(resolve(exportDir, "brand/inline/tile-studio-small.svg"), "utf8");
      const words = de as Record<string, string>;
      return html
        .replace("<!-- app:sprite -->", sprite)
        .replaceAll("<!-- app:tile -->", tile)
        .replace(/\{\{i:([a-z0-9-]+)\}\}/g, (_, n: string) => icon(n, ""))
        .replace(/\{\{i16:([a-z0-9-]+)\}\}/g, (_, n: string) => icon(n, " sb-icon--16"))
        .replace(/\{\{irow:([a-z0-9-]+)\}\}/g, (_, n: string) => icon(n, " sb-row__icon"))
        .replace(/\{\{([a-zA-Z0-9.]+)\}\}/g, (_, key: string) => {
          if (!(key in words)) throw new Error(`index.html: no string "${key}" in src/strings.ts`);
          return escapeHtml(words[key]);
        });
    },
  };
}

export default defineConfig({
  plugins: [sebaroPage()],
  // Tauri expects a fixed port in dev and the files in dist/ (src-tauri/tauri.conf.json)
  clearScreen: false,
  server: { strictPort: true },
  build: {
    target: "es2022",
    // no inlined assets: every file stays a file under the strict CSP
    assetsInlineLimit: 0,
    modulePreload: { polyfill: false },
  },
});
