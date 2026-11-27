// What omarchy-bar-own-widgets.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  /** Widgets in omarchy-bar/plugins, by id. */
  ids: string[];
};

export const validate = ({ ids }: Options) => ids.length === 0 && "ids is empty";
