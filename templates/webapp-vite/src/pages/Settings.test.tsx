import { act, screen, within } from "@testing-library/react";
import { expect, test } from "vitest";
import { version } from "../../package.json";
import i18n from "../i18n";
import { renderApp } from "../test-app";

/** „Über“ in the settings: the section under its heading. */
async function about(name: string) {
  const heading = await screen.findByRole("heading", { level: 2, name });
  return within(heading.closest("section")!);
}

test("„Über“ shows the tile, the name, the version and the sender „von sebaro“ (core rule 29)", async () => {
  renderApp("/einstellungen");
  const section = await about("Über");
  expect(section.getByRole("heading", { level: 3, name: "Musterapp" })).toBeTruthy();
  expect(document.querySelector(".sb-about-head > .sb-sign-tile.sb-sign-tile--64 > svg")).toBeTruthy();
  expect(section.getByText(version).closest(".sb-about-head__meta")?.textContent).toBe(`Version ${version}`);
  expect(section.getByText("Ein Werkzeug von").closest(".sb-sender")).toBeTruthy();
  expect(document.querySelector('.sb-sender > .sb-keymark[role="img"]')?.getAttribute("aria-label")).toBe("sebaro");
});

test("„About“ says the same in English", async () => {
  await act(() => i18n.changeLanguage("en"));
  renderApp("/einstellungen");
  const section = await about("About");
  expect(section.getByRole("heading", { level: 3, name: "Musterapp" })).toBeTruthy();
  expect(section.getByText(version).closest(".sb-about-head__meta")?.textContent).toBe(`Version ${version}`);
  expect(section.getByText("A tool by").closest(".sb-sender")).toBeTruthy();
  expect(document.querySelector('.sb-sender > .sb-keymark[role="img"]')?.getAttribute("aria-label")).toBe("sebaro");
});
