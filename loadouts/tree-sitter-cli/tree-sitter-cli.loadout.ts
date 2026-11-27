import { program, withBrew, withOmarchy } from "loadout";

export const treeSitterCli = program("tree-sitter-cli", { canBeInstalled: [withBrew, withOmarchy] });
