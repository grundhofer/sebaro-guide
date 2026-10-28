#!/usr/bin/env node
// sebaro-sync.mjs: copies the sebaro web export into this template and checks the copy.
// Node 20+, standard library only.
//
//   npm run sebaro:sync                         # from ../../docs/sebaro (this template inside the sebaro-guide repo)
//   npm run sebaro:sync -- --from <folder>      # from another copy of the export (e.g. a fresh sebaro-guide checkout)
//   SEBARO_EXPORT=<folder> npm run sebaro:sync  # the same through the environment
//
// The export is copied as one folder, unchanged (never edit inside it), to the target below. Then the export's own
// checks/verify-export.mjs runs on the copy with --strict: every file must match sebaro-export.json, and nothing else
// may be in the folder. The copied files are committed, so the template works without the guide next to it.
// Exit codes: 0 copied and verified · 1 the copy does not verify · 2 no export at the source.

import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");
const TARGET = path.join(root, "public", "sebaro");

function sourceFolder(argv) {
  const i = argv.indexOf("--from");
  if (i >= 0 && argv[i + 1]) return path.resolve(argv[i + 1]);
  if (process.env.SEBARO_EXPORT) return path.resolve(process.env.SEBARO_EXPORT);
  return path.resolve(root, "..", "..", "docs", "sebaro");
}

const source = sourceFolder(process.argv.slice(2));
if (!fs.existsSync(path.join(source, "sebaro-export.json"))) {
  console.error(`sebaro-sync: ${source} has no sebaro-export.json; pass the export folder with --from <folder>`);
  process.exit(2);
}
fs.rmSync(TARGET, { recursive: true, force: true });
fs.mkdirSync(path.dirname(TARGET), { recursive: true });
fs.cpSync(source, TARGET, {
  recursive: true,
  // dotfiles (.DS_Store) are never part of an export
  filter: (src) => !path.basename(src).startsWith("."),
});
const record = JSON.parse(fs.readFileSync(path.join(TARGET, "sebaro-export.json"), "utf8"));
console.log(`sebaro-sync: copied ${record.files.length} files (sebaroDesign ${String(record.sebaroDesign?.commit).slice(0, 7)}, ` +
  `token contract ${record.contracts?.tokens}) to ${path.relative(root, TARGET)}`);
const check = spawnSync(process.execPath, [path.join(TARGET, "checks", "verify-export.mjs"), TARGET, "--strict"], { stdio: "inherit" });
process.exit(check.status ?? 1);
