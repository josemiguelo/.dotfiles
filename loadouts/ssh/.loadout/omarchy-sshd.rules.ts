// What omarchy-sshd.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  /** The GitHub keys, by title, that get a shell here. */
  keys: string[];
};

export const validate = ({ keys }: Options) => keys.length === 0 && "keys is empty: nobody could log in";
