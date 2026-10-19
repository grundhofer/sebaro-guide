// theme-init.js: apply a stored "Hell oder Dunkel" choice before first paint (spec/09 §2, TOKEN-CONTRACT §9).
// Load it in <head> before the stylesheets, as a classic script: a file keeps pages working under a CSP without
// 'unsafe-inline'. Nothing stored = the page follows prefers-color-scheme.
// It also applies the app setting „Bewegung immer reduzieren“ (D46, spec/03 §13): sb-motion = "reduce" sets
// html[data-sb-motion="reduce"], which sebaro.css and sb-start.js treat like prefers-reduced-motion: reduce.
try { var t = localStorage.getItem("sb-theme"); if (t === "light" || t === "dark") document.documentElement.dataset.theme = t; } catch (e) {}
try { if (localStorage.getItem("sb-motion") === "reduce") document.documentElement.dataset.sbMotion = "reduce"; } catch (e) {}
