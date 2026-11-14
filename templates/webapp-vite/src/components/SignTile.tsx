import tile from "../../sebaro-product/sign/tile.svg?raw";

/** The product's sign tile beside its name: the file the kit of the copy wrote, inline. */
export function SignTile({ size }: { size: 32 | 48 | 64 }) {
  return (
    <span
      className={`sb-sign-tile sb-sign-tile--${size}`}
      aria-hidden="true"
      dangerouslySetInnerHTML={{ __html: tile }}
    />
  );
}
