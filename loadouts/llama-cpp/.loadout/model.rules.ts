// What model.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  /** The Hugging Face repo. */
  repo: string;
  /** Its commit, so a re-upload can't change the file. */
  commit: string;
  file: string;
  sha256: string;
};

export const validate = ({ commit, sha256 }: Options) =>
  (!/^[0-9a-f]{40}$/.test(commit) && "commit is a full commit hash") || (!/^[0-9a-f]{64}$/.test(sha256) && "sha256 is 64 hex digits");
