import { brew, program } from "loadout";

export const awscli = program("awscli", { later: "a large Homebrew install; nothing in setup needs it", install: [brew] });
