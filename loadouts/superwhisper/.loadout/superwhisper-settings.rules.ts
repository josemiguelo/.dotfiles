// What superwhisper-settings.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  processing: "cloud" | "offline" | "offline_lite";
  /** General settings with a string value: language, tone. */
  general?: Record<string, string>;
};

// The type says it all, and Superwhisper's own CLI validates each value.
export const validate = (_: Options) => undefined;
