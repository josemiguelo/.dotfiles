// Every per-machine setting, with its default. Dotfile templates branch on
// these, not on hostnames. Its type checks every machine's and profile's data.
import { flag, number } from "loadout";

export const schema = {
  // An Omarchy machine (Linuxbrew reaches the shell from the zsh config).
  omarchy: flag(false),

  // The work machine: work-only tools in, personal ones (e.g. Copilot) out;
  // the rest comes from its private child repo.
  work: flag(false),

  kitty: {
    // background_opacity; Omarchy's scratchpad repaints its own windows on top.
    opacity: number(0.85),
  },
};

export type Data = typeof schema;
