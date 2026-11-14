// vite.config.ts: Vite with one small plugin for the sebaro copy in src/sebaro/ (never edited) and the product's own
// files in sebaro-product/ (written by the kit of the copy from sebaro.product.json).
import { readFileSync } from "node:fs";
import type { Plugin } from "vite";
import { defineConfig } from "vitest/config";

// Files a bundler does not bundle, served under these addresses as they are: the classic scripts of the copy that
// index.html loads, and the product's icons and manifest, which its head snippet names at the root.
const SERVED: Record<string, string> = {
  "sebaro/js/theme-init.js": "src/sebaro/js/theme-init.js",
  "sebaro/js/sb-start.js": "src/sebaro/js/sb-start.js",
  "favicon.ico": "sebaro-product/web/favicon.ico",
  "icon.svg": "sebaro-product/web/icon.svg",
  "apple-touch-icon.png": "sebaro-product/web/apple-touch-icon.png",
  "icon-192.png": "sebaro-product/web/icon-192.png",
  "icon-512.png": "sebaro-product/web/icon-512.png",
  "icon-mask.png": "sebaro-product/web/icon-mask.png",
  "manifest.webmanifest": "sebaro-product/web/manifest.webmanifest",
};

const read = (file: string) => readFileSync(new URL(file, import.meta.url));

// The start: the copy's markup with the product's id from its declaration and the bare sign the kit wrote into
// sebaro-product/. Its colours come from the product's product.css, which src/app.css imports.
function start(): string {
  const { id } = JSON.parse(read("sebaro.product.json").toString()) as { id: string };
  const sign = read("sebaro-product/sign/sign.svg").toString().trim();
  return `<div class="sb-start" data-sb-product="${id}" aria-hidden="true"><span class="sb-start__tile">${sign}</span></div>`;
}

function sebaro(): Plugin {
  return {
    name: "sebaro",
    // dev: the address leads to the file in its folder
    configureServer(server) {
      server.middlewares.use((req, _res, next) => {
        const file = SERVED[(req.url ?? "").slice(1)];
        if (file) req.url = `/${file}`;
        next();
      });
    },
    // build: the file is written to dist/ under its address
    generateBundle() {
      for (const [fileName, file] of Object.entries(SERVED))
        this.emitFile({ type: "asset", fileName, source: read(file) });
    },
    // the start as the first element of the body, then the icon sprite inline; the product's head snippet in the head
    transformIndexHtml(html) {
      return html
        .replace("<!-- sebaro:start -->", start)
        .replace("<!-- sebaro:sprite -->", () => read("src/sebaro/icons/sprite.svg").toString().trim())
        .replace("<!-- sebaro:head -->", () => read("sebaro-product/web/head.snippet.html").toString().trim());
    },
  };
}

export default defineConfig({
  plugins: [sebaro()],
  build: {
    // the Content-Security-Policy allows no inline script (the module preload helper) and no data: address (a small
    // file inlined into the CSS)
    modulePreload: { polyfill: false },
    assetsInlineLimit: 0,
  },
  test: {
    environment: "jsdom",
    include: ["src/**/*.test.{ts,tsx}"],
    setupFiles: ["src/test-setup.ts"],
  },
});
