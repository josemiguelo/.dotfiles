// unixodbc: a library, not a tool; usql links against it.
import { brew, program } from "loadout";

// usql (a work repo's bootstrap-env.sh) links against it at a fixed path;
// without it usql dies with a dyld error.
export const unixodbc = program("unixodbc", { install: [brew] });
