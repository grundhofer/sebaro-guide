#!/usr/bin/env node
// site-root.mjs: copies the files a browser fetches from the site root (favicons, manifest) out of the export's
// brand/site-root/ into public/, as the export's README asks (head.snippet.html and manifest.snippet.json are not
// copied; their lines are in src/layouts/Base.astro). Run by `npm run sebaro:sync` after the export is copied.
// These files are the umbrella sign of sebaro (a placeholder): a real product puts the files of its own export here.
// They are brand files (all rights reserved, LICENSE.md in public/sebaro/), not under the template's licence.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const from = path.join(root, "public", "sebaro", "brand", "site-root");
const skip = new Set(["head.snippet.html", "manifest.snippet.json"]);
for (const name of fs.readdirSync(from)) {
  if (skip.has(name) || name.startsWith(".")) continue;
  fs.copyFileSync(path.join(from, name), path.join(root, "public", name));
  console.log(`site-root: public/${name}`);
}
