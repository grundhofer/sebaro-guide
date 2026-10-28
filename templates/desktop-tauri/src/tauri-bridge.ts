// tauri-bridge.ts: the two calls the page makes to the Rust side, through the global API that Tauri injects with
// app.withGlobalTauri (no @tauri-apps/api package needed). In a plain browser (vite preview, the Playwright tests) there
// is no window.__TAURI__ and both calls do nothing, so the same frontend runs in both.
type TauriGlobal = {
  core: { invoke: (cmd: string, args?: Record<string, unknown>) => Promise<unknown> };
  window: { getCurrentWindow: () => { setTitle: (title: string) => Promise<void> } };
};

function tauri(): TauriGlobal | undefined {
  return (window as unknown as { __TAURI__?: TauriGlobal }).__TAURI__;
}

/** DSK-14: the Rust side stores the choice in appearance.json and sets ground and theme of every window. */
export function reportAppearance(theme: "system" | "light" | "dark", tone: "cool" | "warm"): void {
  tauri()?.core.invoke("set_appearance", { theme, tone }).catch(() => { /* the page keeps its own choice either way */ });
}

/** DSK-06: the system's window title reads „<Ort> · <App>“. */
export function setWindowTitle(title: string): void {
  tauri()?.window.getCurrentWindow().setTitle(title).catch(() => { /* not allowed or no window: keep the old title */ });
}
