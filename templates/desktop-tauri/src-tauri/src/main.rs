// Musterapp Desktop (fictive): the minimal Rust side of a sebaro desktop app.
// DSK-14: the main window is made here, not in tauri.conf.json. The app keeps „Hell oder Dunkel“ and „Farbton“ in its
// own appearance.json, picks the window ground (from the exported tokens.css, see build.rs) and the system theme from
// it, and hands the choice to the page before the page's scripts (theme-init.js reads it from localStorage). When the
// page changes the choice, set_appearance stores it and sets ground and theme of every window.
// DSK-06: on macOS our 48 px bar is the title bar (overlay style, hidden title); Windows and Linux keep the system frame.
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use serde::{Deserialize, Serialize};
use std::{fs, path::PathBuf};
use tauri::{window::Color, AppHandle, Manager, Theme, WebviewUrl, WebviewWindowBuilder};

include!(concat!(env!("OUT_DIR"), "/grounds.rs"));

#[derive(Serialize, Deserialize, Clone)]
struct Appearance {
    /// "system" | "light" | "dark"
    theme: String,
    /// "cool" | "warm"
    tone: String,
}

impl Default for Appearance {
    fn default() -> Self {
        Self { theme: "system".into(), tone: "cool".into() }
    }
}

fn appearance_file(app: &AppHandle) -> Option<PathBuf> {
    app.path().app_config_dir().ok().map(|dir| dir.join("appearance.json"))
}

fn load(app: &AppHandle) -> Appearance {
    appearance_file(app)
        .and_then(|f| fs::read_to_string(f).ok())
        .and_then(|s| serde_json::from_str::<Appearance>(&s).ok())
        .filter(|a| ["system", "light", "dark"].contains(&a.theme.as_str()) && ["cool", "warm"].contains(&a.tone.as_str()))
        .unwrap_or_default()
}

fn system_theme(a: &Appearance) -> Option<Theme> {
    match a.theme.as_str() {
        "light" => Some(Theme::Light),
        "dark" => Some(Theme::Dark),
        _ => None,
    }
}

fn ground(dark: bool, warm: bool) -> Color {
    let [r, g, b] = match (dark, warm) {
        (false, false) => GROUND_LIGHT,
        (true, false) => GROUND_DARK,
        (false, true) => GROUND_WARM_LIGHT,
        (true, true) => GROUND_WARM_DARK,
    };
    Color(r, g, b, 255)
}

fn apply(window: &tauri::WebviewWindow, a: &Appearance) {
    let _ = window.set_theme(system_theme(a));
    // "system": the theme the system shows now
    let dark = match system_theme(a) {
        Some(t) => t == Theme::Dark,
        None => window.theme().map(|t| t == Theme::Dark).unwrap_or(false),
    };
    let _ = window.set_background_color(Some(ground(dark, a.tone == "warm")));
}

#[tauri::command]
fn set_appearance(app: AppHandle, theme: String, tone: String) -> Result<(), String> {
    let a = Appearance { theme, tone };
    if !["system", "light", "dark"].contains(&a.theme.as_str()) || !["cool", "warm"].contains(&a.tone.as_str()) {
        return Err("unknown appearance".into());
    }
    if let Some(file) = appearance_file(&app) {
        if let Some(dir) = file.parent() {
            fs::create_dir_all(dir).map_err(|e| e.to_string())?;
        }
        fs::write(&file, serde_json::to_string_pretty(&a).map_err(|e| e.to_string())?).map_err(|e| e.to_string())?;
    }
    for window in app.webview_windows().values() {
        apply(window, &a);
    }
    Ok(())
}

/// The script that runs in the page before its own scripts: the stored choice as theme-init.js expects it
/// (only "warm" is stored as sb-tone, FAR-15), and the platform for the shortcut text (sb-window.js).
fn init_script(a: &Appearance) -> String {
    let platform = match std::env::consts::OS {
        "macos" => "mac",
        "windows" => "windows",
        _ => "linux",
    };
    let theme = if a.theme == "system" { "null".to_string() } else { format!("{:?}", a.theme) };
    let tone = if a.tone == "warm" { "\"warm\"" } else { "null" };
    format!(
        "(function () {{ try {{ var t = {theme}, w = {tone};\n\
         if (t) localStorage.setItem('sb-theme', t); else localStorage.removeItem('sb-theme');\n\
         if (w) localStorage.setItem('sb-tone', w); else localStorage.removeItem('sb-tone'); }} catch (e) {{}}\n\
         document.documentElement.setAttribute('data-sb-platform', '{platform}'); }})();"
    )
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![set_appearance])
        .setup(|app| {
            let a = load(app.handle());
            let builder = WebviewWindowBuilder::new(app, "main", WebviewUrl::App("index.html".into()))
                .title("Musterapp Desktop")
                .inner_size(1200.0, 800.0)
                .min_inner_size(480.0, 400.0)
                .theme(system_theme(&a))
                .background_color(ground(system_theme(&a) == Some(Theme::Dark), a.tone == "warm"))
                .initialization_script(&init_script(&a));
            #[cfg(target_os = "macos")]
            let builder = builder.title_bar_style(tauri::TitleBarStyle::Overlay).hidden_title(true);
            let window = builder.build()?;
            apply(&window, &a);
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running Musterapp Desktop");
}
