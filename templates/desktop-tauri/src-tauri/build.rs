// build.rs: Tauri's build step, plus the four window grounds of DSK-14 read from the exported tokens.css at build time
// (light, dark, warm light, warm dark), so no colour value is copied by hand into the Rust code (TEC-01). The guide's
// web export has no tokens.json; tokens.css is generated from it by the same build (its header names the source).
// The build fails loud when a ground is missing, e.g. after an export that changed the selectors.
use std::{env, fs, path::Path};

fn ground(css: &str, selector: &str) -> [u8; 3] {
    // the rule blocks of tokens.css: "<selector> {" … "}" (inside @media too); compare the selector without spaces
    let want: String = selector.split_whitespace().collect();
    let mut rest = css;
    while let Some(open) = rest.find('{') {
        let head = &rest[..open];
        let sel = head.rsplit(['}', ';', '/']).next().unwrap_or("");
        let body_end = rest[open..].find('}').map(|i| open + i).unwrap_or(rest.len());
        let body = &rest[open + 1..body_end];
        if sel.split_whitespace().collect::<String>() == want {
            for decl in body.split(';') {
                if let Some(v) = decl.trim().strip_prefix("--sb-color-bg:") {
                    let hex = v.trim().trim_start_matches('#');
                    let byte = |i: usize| u8::from_str_radix(&hex[i..i + 2], 16).expect("tokens.css: --sb-color-bg is no #RRGGBB");
                    return [byte(0), byte(2), byte(4)];
                }
            }
        }
        rest = &rest[body_end.min(rest.len() - 1) + 1..];
    }
    panic!("tokens.css: no --sb-color-bg in the block {selector:?}; export again or adapt build.rs");
}

fn main() {
    let tokens = Path::new(env!("CARGO_MANIFEST_DIR")).join("../public/sebaro/tokens.css");
    println!("cargo:rerun-if-changed={}", tokens.display());
    let css = fs::read_to_string(&tokens).expect("public/sebaro/tokens.css missing: run npm run sebaro:sync");
    let light = ground(&css, ":root, [data-theme=\"light\"]");
    let dark = ground(&css, "[data-theme=\"dark\"]");
    let warm_light = ground(&css, ":root[data-sb-tone=\"warm\"], :root[data-sb-tone=\"warm\"] [data-theme=\"light\"]");
    let warm_dark = ground(&css, ":root[data-sb-tone=\"warm\"][data-theme=\"dark\"], :root[data-sb-tone=\"warm\"] [data-theme=\"dark\"]");
    let out = Path::new(&env::var("OUT_DIR").unwrap()).join("grounds.rs");
    fs::write(
        out,
        format!(
            "pub const GROUND_LIGHT: [u8; 3] = {light:?};\npub const GROUND_DARK: [u8; 3] = {dark:?};\n\
             pub const GROUND_WARM_LIGHT: [u8; 3] = {warm_light:?};\npub const GROUND_WARM_DARK: [u8; 3] = {warm_dark:?};\n"
        ),
    )
    .unwrap();
    tauri_build::build()
}
