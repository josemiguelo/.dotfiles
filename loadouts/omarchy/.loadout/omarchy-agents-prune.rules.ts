// What omarchy-agents-prune.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  /** The agents that stay. */
  keep: string[];
};

// The type says it all: keeping none is allowed.
export const validate = (_: Options) => undefined;
