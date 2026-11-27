// What omarchy-theme-mode.ts takes, and what would be wrong with it: compile runs this file, so
// nothing else goes in it.
export type Options = { dark: string; light: string };

export const validate = ({ dark, light }: Options) => (dark === "" || light === "") && "dark and light are themes, as omarchy theme list prints them";
