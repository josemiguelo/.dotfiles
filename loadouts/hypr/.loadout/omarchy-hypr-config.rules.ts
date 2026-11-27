// What omarchy-hypr-config.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  /** The hypr-config/<file>.lua files, by name. */
  files: string[];
};

export const validate = ({ files }: Options) => files.length === 0 && "files is empty";
