// What gpu.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = {
  /** The GPU's <vendor>:<device> (lspci -nn). */
  pciId: string;
};

export const validate = ({ pciId }: Options) => !/^[0-9a-f]{4}:[0-9a-f]{4}$/.test(pciId) && `pciId is <vendor>:<device>, as lspci -nn prints it, not '${pciId}'`;
