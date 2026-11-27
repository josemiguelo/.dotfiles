// What github-ssh-key.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
/** HOME/.ssh/name, the cwd, PATH and the agent set up for what follows. */
export type Options = {
  /** setup-ssh's key, by its file's name in ~/.ssh. */
  key: string;
};

export const validate = ({ key }: Options) => !/^[\w.-]+$/.test(key) && "key is a file's name in ~/.ssh";
