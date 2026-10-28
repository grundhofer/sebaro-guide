// The webview's frontend, tested in Chromium (D96 (b): CI checks in Chromium only). Tauri's own webviews (WebKit on
// macOS and Linux, WebView2 on Windows) are not tested here. Run `npm run build` first; the server serves dist/.
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "tests",
  fullyParallel: true,
  workers: process.env.CI ? 2 : undefined,
  reporter: [["list"]],
  use: { baseURL: "http://127.0.0.1:4174", browserName: "chromium" },
  webServer: {
    command: "npm run preview",
    url: "http://127.0.0.1:4174",
    reuseExistingServer: !process.env.CI,
  },
});
