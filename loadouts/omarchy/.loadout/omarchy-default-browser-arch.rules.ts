// What omarchy-default-browser-arch.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = { browser: string };

export const validate = ({ browser }: Options) => browser === "" && "browser is empty";
