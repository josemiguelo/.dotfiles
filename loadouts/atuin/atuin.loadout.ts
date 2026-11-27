// atuin: shell history. Its zsh side is zsh's .zshrc and theme.zsh here, its
// settings ~/.atuin/config.toml.
import { program, script, withBrew, withOmarchy } from "loadout";
import { onepasswordSignin } from "../1password/1password.loadout.ts";

export const atuin = program("atuin", { canBeInstalled: [withBrew, withOmarchy] });

// Its sync account: on a new machine it asks for the login and waits, like
// onepassword-signin, and after it, so the credentials can be copied from the app.
export const atuinLogin = script("atuin-login", {
  description: "atuin logged in to its sync account",
  module: () => import("./.loadout/login.ts"),
  runAfter: [atuin, onepasswordSignin],
});
