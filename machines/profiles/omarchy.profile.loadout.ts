import { profile, withBrew, withBrewCask, withFlatpak, withOmarchy, withOmarchyAur } from "loadout";
import type { Data } from "../data.ts";
import { keychronLauncherAccess } from "../../loadouts/keychron/keychron.loadout.ts";
import { git, setupGit } from "../../loadouts/git/git.loadout.ts";
import { skillsRepo } from "../../loadouts/claude/claude.loadout.ts";
import { n1passwordCli, omarchy1password, onePassword, onepasswordSignin } from "../../loadouts/1password/1password.loadout.ts";
import { androidSdk } from "../../loadouts/android-sdk/android-sdk.loadout.ts";
import { anydesk } from "../../loadouts/anydesk/anydesk.loadout.ts";
import { awscli } from "../../loadouts/awscli/awscli.loadout.ts";
import { atuinLogin } from "../../loadouts/atuin/atuin.loadout.ts";
import { brave, omarchyBrave } from "../../loadouts/brave/brave.loadout.ts";
import { code, omarchyVscode } from "../../loadouts/code/code.loadout.ts";
import { curl } from "../../loadouts/curl/curl.loadout.ts";
import { gcc } from "../../loadouts/gcc/gcc.loadout.ts";
import { googleCloudCli } from "../../loadouts/gcloud/gcloud.loadout.ts";
import { ghostscript } from "../../loadouts/ghostscript/ghostscript.loadout.ts";
import { unlinkBrewGlib } from "../../loadouts/homebrew/brew-glib.loadout.ts";
import { withBrewTap, setupBrew } from "../../loadouts/homebrew/homebrew.loadout.ts";
import { omarchyCloseWindowKey, omarchyHarpoon, omarchyHyprConfig, omarchyThemeMode } from "../../loadouts/hypr/hyprland.loadout.ts";
import { intentional } from "../../loadouts/intentional/intentional.loadout.ts";
import { just } from "../../loadouts/just/just.loadout.ts";
import { libxcryptCompat } from "../../loadouts/libxcrypt-compat/libxcrypt-compat.loadout.ts";
import { obsidian } from "../../loadouts/obsidian/obsidian.loadout.ts";
import { omarchyAgentsPrune, omarchyDefaultBrowser, omarchyDefaultDictation } from "../../loadouts/omarchy/omarchy-apps.loadout.ts";
import { omarchyCommandOverrides, omarchyKeyboardBacklightGuard } from "../../loadouts/omarchy/omarchy-overrides.loadout.ts";
import { omarchyPackageLists } from "../../loadouts/omarchy/omarchy-package-lists.loadout.ts";
import { omarchyBarFn, omarchyIdle, omarchyWorkspaceLayoutMenu } from "../../loadouts/omarchy/omarchy-shell.loadout.ts";
import { omarchyWebappClaude, omarchyWebappGmail, omarchyWebappGoogleCalendar, omarchyWebappsRemove } from "../../loadouts/omarchy/omarchy-webapps.loadout.ts";
import { procpsNg } from "../../loadouts/procps-ng/procps-ng.loadout.ts";
import { rtkit } from "../../loadouts/rtkit/rtkit.loadout.ts";
import { scrcpy } from "../../loadouts/scrcpy/scrcpy.loadout.ts";
import { slack } from "../../loadouts/slack/slack.loadout.ts";
import { spotify } from "../../loadouts/spotify/spotify.loadout.ts";
import { stremio } from "../../loadouts/stremio/stremio.loadout.ts";
import { sublimeText } from "../../loadouts/sublime-text/sublime-text.loadout.ts";
import { superwhisperSettings } from "../../loadouts/superwhisper/superwhisper.loadout.ts";
import { teamsForLinux } from "../../loadouts/teams-for-linux/teams-for-linux.loadout.ts";
import { trashCli } from "../../loadouts/trash-cli/trash-cli.loadout.ts";
import { vim } from "../../loadouts/vim/vim.loadout.ts";
import { vlc } from "../../loadouts/vlc/vlc.loadout.ts";
import { yq } from "../../loadouts/yq/yq.loadout.ts";
import { chezmoi, dotfilesAll } from "../../loadouts/chezmoi/chezmoi.loadout.ts";
import { kitty, omarchyDefaultTerminal, ttfFiracodeNerd } from "../../loadouts/kitty/kitty.loadout.ts";
import { mise, miseDefaultPackages, miseTools, miseToolsLater, omarchyDefaultAgent, openssl11 } from "../../loadouts/mise/mise.loadout.ts";
import { masonKotlinLsp, nvimPlugins } from "../../loadouts/nvim/nvim.loadout.ts";
import { ngrok } from "../../loadouts/ngrok/ngrok.loadout.ts";
import { omarchyTmuxTheme, removeBrewTmux, tmux, tmuxPlugins, tpack } from "../../loadouts/tmux/tmux.loadout.ts";
import { workmux, workmuxSetup } from "../../loadouts/workmux/workmux.loadout.ts";
import { defaultShell, zsh } from "../../loadouts/zsh/zsh.loadout.ts";
import { flathubRemote, flatpakProgram } from "../../loadouts/flatpak/flatpak.loadout.ts";
import { jetbrainsToolbox, linkJetbrainsLaunchersLinux } from "../../loadouts/jetbrains/jetbrains.loadout.ts";
import { everydayCli, shellScripts } from "./shared.loadout.ts";

// Every Omarchy machine: Omarchy's own installer for system packages, brew
// where Arch's package lags behind (trash-cli, awscli, vim) or is another
// tool under the same name (Arch's yq is kislyuk's, not mikefarah's).
export const omarchyProfile = profile<Data>("omarchy", {
  data: { omarchy: true },
  install: [
    withOmarchy(
      curl,
      git,
      gcc,
      procpsNg,
      zsh,
      chezmoi,
      mise,
      kitty,
      tmux,
      everydayCli,
      code,
      sublimeText,
      obsidian,
      spotify,
      vlc,
      onePassword,
      n1passwordCli,
      ttfFiracodeNerd,
      ghostscript,
      flatpakProgram,
      libxcryptCompat,
      rtkit,
    ),
    withFlatpak(flathubRemote, stremio),
    withOmarchyAur(slack, teamsForLinux, anydesk, brave, openssl11),
    omarchyPackageLists,
    setupBrew("linux"),
    jetbrainsToolbox("linux"),
    tpack("linux"),
    ngrok,
    intentional,
    withBrew(just, vim, scrcpy, awscli, trashCli, yq),
    withBrewTap(workmux),
    withBrewCask(googleCloudCli),
  ],
  run: [
    // claude comes from mise here (Omarchy's /etc/mise/conf.d/omarchy-tools.toml).
    dotfilesAll,
    setupGit,
    skillsRepo,
    workmuxSetup,
    defaultShell,
    nvimPlugins,
    masonKotlinLsp,
    unlinkBrewGlib,
    keychronLauncherAccess,
    shellScripts,
    // Each tool's default version now; the older ones and the rest later.
    miseTools({ tools: ["node", "python", "neovim", "go"] }),
    miseToolsLater,
    miseDefaultPackages,
    omarchyDefaultAgent({ agent: "claude" }),
    omarchyDefaultTerminal,
    tmuxPlugins,
    removeBrewTmux,
    omarchyTmuxTheme,
    linkJetbrainsLaunchersLinux,
    androidSdk,
    // Hyprland
    omarchyHyprConfig({ files: ["input", "looknfeel", "bindings"] }),
    omarchyCloseWindowKey,
    omarchyHarpoon,
    omarchyThemeMode({ dark: "tokyo-night", light: "catppuccin-latte" }),
    omarchyBarFn(),
    omarchyWorkspaceLayoutMenu,
    // Apps the Omarchy way
    omarchy1password,
    onepasswordSignin,
    // Waits on a new machine for the atuin login; only these machines share
    // a history, so it's not in shared's lists.
    atuinLogin,
    omarchyVscode,
    omarchyBrave,
    omarchyDefaultBrowser({ browser: "brave" }),
    omarchyAgentsPrune({ keep: ["claude", "codex", "gh", "gemini"] }),
    // Web apps: Google's in HEY's place
    omarchyWebappsRemove({ names: ["Basecamp", "HEY"] }),
    omarchyWebappGmail,
    omarchyWebappGoogleCalendar,
    omarchyWebappClaude,
    omarchyCommandOverrides,
    omarchyKeyboardBacklightGuard,
    // The screensaver gets ~14 minutes (it starts at 150s) before the lock.
    omarchyIdle({ lockSeconds: 1000 }),
    omarchyDefaultDictation,
    superwhisperSettings({ processing: "offline", general: { language: "auto" } }),
  ],
});
