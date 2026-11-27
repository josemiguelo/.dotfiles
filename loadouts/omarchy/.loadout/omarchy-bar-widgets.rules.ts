// What omarchy-bar-widgets.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
/** Omarchy's bar sections. */
export type Section = "left" | "centerBegin" | "center" | "centerEnd" | "tray" | "right";

/** A widget in a section: right before or after another, or at an index. */
export type Widget = { id: string; section: Section } & (
  | { before: string; after?: never; at?: never }
  | { after: string; before?: never; at?: never }
  | { at: number; before?: never; after?: never }
);

export type Options = { widgets: Widget[] };

export const validate = ({ widgets }: Options) =>
  (widgets.length === 0 && "widgets is empty") ||
  (widgets.some(({ at }) => at !== undefined && !(Number.isInteger(at) && at >= 0)) && "a widget's at is an index: 0, 1, …");
