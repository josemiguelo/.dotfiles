import { program, withOmarchy } from "loadout";

export const vlc = program("vlc", { description: "VLC media player", canBeInstalled: [withOmarchy] });
