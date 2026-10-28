// Astro for a static sebaro website. Kept small on purpose:
// - every page is static HTML; sebaro's own classic scripts come from public/sebaro/js/ (no islands, no frameworks)
// - stylesheets are always files (inlineStylesheets: "never"), so the strict Content-Security-Policy in
//   src/layouts/Base.astro needs no 'unsafe-inline'
// - no syntax highlighter: Shiki writes style="" attributes, which that policy forbids; code is marked up with
//   sebaro's sb-tok-* spans instead (TEC-08, TXT-10)
import { defineConfig } from "astro/config";

export default defineConfig({
  site: "https://example.org",
  trailingSlash: "always",
  build: { format: "directory", inlineStylesheets: "never" },
  markdown: { syntaxHighlight: false },
  devToolbar: { enabled: false },
  vite: { build: { assetsInlineLimit: 0 } },
});
