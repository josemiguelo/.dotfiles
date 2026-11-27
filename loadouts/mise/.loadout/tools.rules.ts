// What tools.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  /** Only these tools' default versions; every version of every tool without it. */
  tools: string[];
};

export const validate = (options?: Options) => options?.tools.length === 0 && "tools is empty: leave the options out for every tool";
