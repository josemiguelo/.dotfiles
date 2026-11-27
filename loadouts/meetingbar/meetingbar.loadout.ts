import { program, withBrewCask } from "loadout";

export const meetingbar = program("meetingbar", { description: "MeetingBar -- calendar meetings in the menu bar", canBeInstalled: [withBrewCask] });
