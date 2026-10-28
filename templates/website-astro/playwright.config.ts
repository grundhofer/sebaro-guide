// Playwright runs the built site (npm run build first) in Chromium only, like the guide's own checks (D96 (b)).
import { defineConfig } from "@playwright/test";

const PORT = 4321;

export default defineConfig({
  testDir: "tests",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: 0,
  workers: process.env.CI ? 2 : undefined,
  reporter: process.env.CI ? [["list"], ["html", { open: "never" }]] : "list",
  use: { baseURL: `http://127.0.0.1:${PORT}`, browserName: "chromium" },
  webServer: {
    command: `npx astro preview --port ${PORT} --host 127.0.0.1 --ignore-lock`,
    url: `http://127.0.0.1:${PORT}/`,
    reuseExistingServer: !process.env.CI,
    timeout: 60_000,
  },
});
