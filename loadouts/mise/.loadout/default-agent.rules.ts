// What default-agent.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = { agent: string };

export const validate = ({ agent }: Options) => agent === "" && "agent is empty";
