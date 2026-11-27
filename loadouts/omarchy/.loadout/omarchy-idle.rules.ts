// What omarchy-idle.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  /** Idle seconds before the lock. */
  lockSeconds: number;
};

export const validate = ({ lockSeconds }: Options) => !(Number.isInteger(lockSeconds) && lockSeconds >= 0) && "lockSeconds is a whole number";
