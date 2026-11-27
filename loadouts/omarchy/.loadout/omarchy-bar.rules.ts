// What omarchy-bar.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  position: "top" | "bottom" | "left" | "right";
  /** The bar's thickness at font base-size 12. */
  size: number;
  /** Left as it is without one. */
  background?: "opaque" | "glassy" | "none";
  iconSize?: number;
  /** Stock widgets turned off, by id. */
  off?: string[];
};

export const validate = ({ size, iconSize = 0 }: Options) => ![size, iconSize].every((n) => Number.isInteger(n) && n >= 0) && "size and iconSize are whole numbers";
