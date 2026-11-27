// What omarchy-plugins.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  /** Git URLs, one per plugin. */
  urls: string[];
};

export const validate = ({ urls }: Options) => urls.length === 0 && "urls is empty";
