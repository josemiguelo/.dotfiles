// What llama-server.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  /** One of llm-model's files. */
  model: string;
  /** The model's name in the API. */
  alias: string;
  host: string;
  port: number;
  /** The GPU to run on, by a word of its name ("Radeon"). */
  gpu?: string;
  /** The server's environment. */
  env?: Record<string, string | number>;
  /** llama-server's own flags, in order, as it spells them; true is a flag with no value. */
  flags?: Record<string, string | number | true>;
};

export const validate = ({ model, alias, host, port, env = {} }: Options) =>
  ([model, alias, host].some((text) => text === "") && "model, alias and host can't be empty") ||
  (!(Number.isInteger(port) && port >= 1 && port <= 65535) && "port is from 1 to 65535") ||
  (Object.keys(env).some((name) => !/^[A-Z_][A-Z0-9_]*$/.test(name)) && "env's names are like GGML_OP_OFFLOAD_MIN_BATCH");
