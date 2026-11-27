// What setup-ssh.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  /** The key's file name in ~/.ssh. */
  key: string;
};

export const validate = ({ key }: Options) => !/^[\w.-]+$/.test(key) && "key is a file's name in ~/.ssh";
