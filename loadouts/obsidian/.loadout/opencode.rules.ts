// What opencode.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  vault: string;
  /** Tokens OpenCode keeps free: it compacts when fewer are left. */
  buffer: number;
  /** Tokens a compaction keeps. */
  keep: number;
  /** The skills it sees. */
  skills: string[];
};

export const validate = ({ buffer, keep, skills }: Options) =>
  (![buffer, keep].every((n) => Number.isInteger(n) && n > 0) && "buffer and keep are whole numbers of tokens") || (skills.length === 0 && "skills is empty");
