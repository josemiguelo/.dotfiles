// What rgignore.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = { vault: string; patterns: string[] };

export const validate = ({ vault, patterns }: Options) =>
  (!/^(~|\/|\$HOME)/.test(vault) && "vault is a path from ~ or /") || (patterns.length === 0 && "patterns is empty");
