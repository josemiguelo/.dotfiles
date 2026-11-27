// What omarchy-scratchpad-opacity.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  /** From 0 to 1. */
  opacity: number;
};

export const validate = ({ opacity }: Options) => !(opacity >= 0 && opacity <= 1) && "opacity is from 0 to 1";
