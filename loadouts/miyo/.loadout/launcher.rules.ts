// What launcher.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  /** The embedding server's GPU, by one word of its name ("Intel"). */
  gpu?: string;
  /** Miyo's environment; a value has no spaces or quotes. */
  env?: Record<string, string>;
};

export const validate = ({ gpu, env = {} }: Options) =>
  (gpu !== undefined && !/^[A-Za-z0-9._-]+$/.test(gpu) && "gpu is one word of the GPU's name") ||
  (Object.entries(env).some(([name, value]) => !/^[A-Z_][A-Z0-9_]*$/.test(name) || /['\s]/.test(value)) && "env is NAME: value, without spaces or quotes");
