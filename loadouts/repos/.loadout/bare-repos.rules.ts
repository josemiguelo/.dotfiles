// What bare-repos.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  repos: string[];
  /** Fetched over ssh too: private ones. */
  ssh?: boolean;
};

export const validate = ({ repos }: Options) => repos.length === 0 && "repos is empty";
