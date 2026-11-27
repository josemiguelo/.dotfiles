// What sync-config.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  /** The name this machine syncs under. */
  device: string;
};

export const validate = ({ device }: Options) => device === "" && "device is empty";
