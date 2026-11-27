// starship: the prompt. Its config is home/private_dot_config/starship.toml.
import { program, withBrew, withOmarchy } from "loadout";

// The shell prompt.
export const starship = program("starship", { canBeInstalled: [withBrew, withOmarchy] });
