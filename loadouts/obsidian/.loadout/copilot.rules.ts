// What copilot.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  vault: string;
  /** llama-server's OpenAI-compatible API. */
  baseUrl: string;
  /** Its model's alias. */
  model: string;
  /** Its context, passed on to OpenCode, which assumes 200K otherwise. */
  context: number;
  /** Miyo results per search. */
  miyoResults: number;
};

export const validate = ({ context, miyoResults }: Options) =>
  (!(Number.isInteger(context) && context > 0) && "context is a whole number of tokens") ||
  (!(Number.isInteger(miyoResults) && miyoResults >= 1 && miyoResults <= 20) && "miyoResults is 1 to 20");
