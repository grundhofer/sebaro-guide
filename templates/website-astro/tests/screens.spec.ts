// Every page of the site, light and dark, at 320, 390 and 1440 px, at 100 % and at real 200 % text
// (checks in sebaro-checks.ts: no sideways scroll, no cut text, axe 0 violations, no console or CSP error).
import type { Page } from "@playwright/test";
import { checkScreens } from "./sebaro-checks";

const openFootnotePopover = async (page: Page) => {
  // below 1024 px the digit opens the note in the popover (BEL-07); from 1024 px it jumps to the note (BEL-02)
  await page.locator("#fnref-1").click();
};

checkScreens([
  { name: "start", path: "/" },
  { name: "start-en", path: "/en/" },
  { name: "apps", path: "/apps/" },
  { name: "projekte", path: "/projekte/" },
  { name: "artikel", path: "/projekte/liste-als-csv/" },
  { name: "artikel-fussnote", path: "/projekte/liste-als-csv/", prepare: openFootnotePopover },
  { name: "ueber", path: "/ueber/" },
  { name: "kontakt", path: "/kontakt/" },
  { name: "impressum", path: "/impressum/" },
  { name: "datenschutz", path: "/datenschutz/" },
  { name: "barrierefreiheit", path: "/barrierefreiheit/" },
  { name: "404", path: "/404.html" },
]);
