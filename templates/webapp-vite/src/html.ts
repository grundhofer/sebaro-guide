// html.ts: a tiny tagged template for markup. Every interpolated value is escaped, unless it is already Html (from
// another html`` call or from raw()). No framework, CSP-safe: the result goes into innerHTML of an element the app
// owns; it never carries inline handlers or style attributes.

export class Html {
  constructor(readonly value: string) {}
  toString(): string {
    return this.value;
  }
}

const ESC: Record<string, string> = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" };

export function escape(text: string): string {
  return text.replace(/[&<>"']/g, (c) => ESC[c]);
}

type Part = Html | string | number | boolean | null | undefined | Part[];

function render(part: Part): string {
  if (part === null || part === undefined || part === false) return "";
  if (Array.isArray(part)) return part.map(render).join("");
  if (part instanceof Html) return part.value;
  return escape(String(part));
}

export function html(strings: TemplateStringsArray, ...parts: Part[]): Html {
  let out = strings[0];
  for (let i = 0; i < parts.length; i++) out += render(parts[i]) + strings[i + 1];
  return new Html(out);
}

/** Markup the app wrote itself (e.g. a string from strings.ts that holds <code> or &nbsp;). Never user input. */
export function raw(markup: string): Html {
  return new Html(markup);
}

/** An icon from the inlined sprite (ICO-04): aria-hidden, never focusable. */
export function icon(name: string, size?: 16 | 20 | 24 | "spot", extra = ""): Html {
  const cls = ["sb-icon", size && size !== 24 ? `sb-icon--${size}` : "", extra].filter(Boolean).join(" ");
  return html`<svg class="${cls}" aria-hidden="true" focusable="false"><use href="#${name}"/></svg>`;
}
