// What charge-limit.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  /** A whole percentage from 1 to 100; the SMC stops 5 points below it. */
  limit: number;
};

export const validate = ({ limit }: Options) =>
  (!Number.isInteger(limit) || limit < 1 || limit > 100) && `the limit is a whole percentage from 1 to 100, not ${limit}`;
