// Every per-machine setting, with its default. Dotfile templates branch on
// these, not on hostnames. Its type checks every machine's and profile's data.
export const schema = {
  // An Omarchy machine (Linuxbrew reaches the shell from the zsh config).
  omarchy: false,

  // The work machine: work-only tools in, personal ones (e.g. Copilot) out;
  // the rest comes from its private child repo.
  work: false,

  // Miyo runs here (docs/local-llm.md): its CLI's folder goes on zsh's PATH.
  miyo: false,

  kitty: {
    // background_opacity; Omarchy's scratchpad repaints its own windows on top.
    opacity: 0.85,
  },
};

export type Data = typeof schema;
