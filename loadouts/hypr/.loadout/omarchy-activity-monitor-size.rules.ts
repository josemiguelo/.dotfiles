// What omarchy-activity-monitor-size.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
/** Pixels, or a share of the monitor. */
export type Size = number | `${number}%`;
export type Options = { width: Size; height: Size };

export const validate = ({ width, height }: Options) =>
  ![width, height].every((size) => (typeof size === "number" ? Number.isInteger(size) && size > 0 : Number(size.slice(0, -1)) > 0)) && "width and height are pixels (1400) or a share of the monitor (80%)";
