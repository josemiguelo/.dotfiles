// What omarchy-webapps-remove.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  /** Web apps, by their launcher's name. */
  names: string[];
};

export const validate = ({ names }: Options) => names.length === 0 && "names is empty";
