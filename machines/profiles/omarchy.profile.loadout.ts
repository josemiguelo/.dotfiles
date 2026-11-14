import { args, brew, brewCask, flatpak, omarchy, omarchyAur, profile, variant, via } from "loadout";
import type { Data } from "../data.ts";
import { keychronLauncherAccess } from "../../loadouts/.etc/keychron/.keychron.loadout.ts";
import { git, setupGit } from "../../loadouts/.gitconfig/.git.loadout.ts";
import { skillsRepo } from "../../loadouts/private_dot_claude/.claude.loadout.ts";
import { n1passwordCli, onePassword, onepasswordCli } from "../../loadouts/private_dot_config/.1password/.1password.loadout.ts";
import { androidSdk } from "../../loadouts/private_dot_config/.android-sdk/.android-sdk.loadout.ts";
import { antigravity } from "../../loadouts/private_dot_config/.antigravity/.antigravity.loadout.ts";
import { anydesk } from "../../loadouts/private_dot_config/.anydesk/.anydesk.loadout.ts";
import { awscli } from "../../loadouts/private_dot_config/.awscli.loadout.ts";
import { brave } from "../../loadouts/private_dot_config/.brave.loadout.ts";
import { code } from "../../loadouts/private_dot_config/.code/.code.loadout.ts";
import { curl } from "../../loadouts/private_dot_config/.curl.loadout.ts";
import { gcc } from "../../loadouts/private_dot_config/.gcc.loadout.ts";
import { googleCloudCli } from "../../loadouts/private_dot_config/.gcloud/.gcloud.loadout.ts";
import { ghostscript } from "../../loadouts/private_dot_config/.ghostscript.loadout.ts";
import { unlinkBrewGlib } from "../../loadouts/private_dot_config/.homebrew/.brew-glib.loadout.ts";
import { brewTap, setupBrew } from "../../loadouts/private_dot_config/.homebrew/.homebrew.loadout.ts";
import { omarchyCloseWindowKey, omarchyGoogleBindings, omarchyHarpoon, omarchyHyprConfig, omarchyThemeMode } from "../../loadouts/private_dot_config/.hypr/.hyprland.loadout.ts";
import { intentional } from "../../loadouts/private_dot_config/.intentional/.intentional.loadout.ts";
import { just } from "../../loadouts/private_dot_config/.just.loadout.ts";
import { libxcryptCompat } from "../../loadouts/private_dot_config/.libxcrypt-compat.loadout.ts";
import { removeLoadoutBunDownloads } from "../../loadouts/private_dot_config/.loadout-cli.loadout.ts";
import { obsidian } from "../../loadouts/private_dot_config/.obsidian/.obsidian.loadout.ts";
import { omarchy1password, omarchyAgentsPrune, omarchyBrave, omarchyDefaultBrowser, omarchyDefaultDictation, omarchyRemoveVoxtypeExtras, omarchyVscode, removeSurfingkeys } from "../../loadouts/private_dot_config/.omarchy/.omarchy-apps.loadout.ts";
import { omarchyCommandOverrides, omarchyKeyboardBacklightGuard } from "../../loadouts/private_dot_config/.omarchy/.omarchy-overrides.loadout.ts";
import { omarchyPackageLists } from "../../loadouts/private_dot_config/.omarchy/.omarchy-package-lists.loadout.ts";
import { omarchyBarFn, omarchyIdle, omarchyWorkspaceLayoutMenu } from "../../loadouts/private_dot_config/.omarchy/.omarchy-shell.loadout.ts";
import { omarchyWebappClaude, omarchyWebappGmail, omarchyWebappGoogleCalendar, omarchyWebappsRemove } from "../../loadouts/private_dot_config/.omarchy/.omarchy-webapps.loadout.ts";
import { procpsNg } from "../../loadouts/private_dot_config/.procps-ng.loadout.ts";
import { rtkit } from "../../loadouts/private_dot_config/.rtkit.loadout.ts";
import { scrcpy } from "../../loadouts/private_dot_config/.scrcpy.loadout.ts";
import { slack } from "../../loadouts/private_dot_config/.slack/.slack.loadout.ts";
import { spotify } from "../../loadouts/private_dot_config/.spotify.loadout.ts";
import { stremio } from "../../loadouts/private_dot_config/.stremio.loadout.ts";
import { sublimeText } from "../../loadouts/private_dot_config/.sublime-text.loadout.ts";
import { superwhisperSettings } from "../../loadouts/private_dot_config/.superwhisper/.superwhisper.loadout.ts";
import { teamsForLinux } from "../../loadouts/private_dot_config/.teams-for-linux.loadout.ts";
import { trashCli } from "../../loadouts/private_dot_config/.trash-cli.loadout.ts";
import { vim } from "../../loadouts/private_dot_config/.vim.loadout.ts";
import { vlc } from "../../loadouts/private_dot_config/.vlc.loadout.ts";
import { yq } from "../../loadouts/private_dot_config/.yq.loadout.ts";
import { chezmoi, dotfilesAll } from "../../loadouts/private_dot_config/chezmoi/.chezmoi.loadout.ts";
import { kitty, omarchyDefaultTerminal, ttfFiracodeNerd } from "../../loadouts/private_dot_config/kitty/.kitty.loadout.ts";
import { mise, miseDefaultPackages, miseTools, miseToolsLater, omarchyDefaultAgent, openssl11 } from "../../loadouts/private_dot_config/mise/.mise.loadout.ts";
import { masonKotlinLsp, nvimPlugins, removeKotlinLspDownload } from "../../loadouts/private_dot_config/nvim/.nvim.loadout.ts";
import { ngrok } from "../../loadouts/private_dot_config/private_ngrok/.ngrok.loadout.ts";
import { omarchyTmuxTheme, removeBrewTmux, tmux, tmuxPlugins, tpack } from "../../loadouts/private_dot_config/tmux/.tmux.loadout.ts";
import { workmux, workmuxSetup } from "../../loadouts/private_dot_config/workmux/.workmux.loadout.ts";
import { defaultShell, zsh } from "../../loadouts/private_dot_config/zsh/.zsh.loadout.ts";
import { flathubRemote, flatpakProgram } from "../../loadouts/private_dot_local/share/.flatpak.loadout.ts";
import { jetbrainsToolbox, linkJetbrainsLaunchersLinux } from "../../loadouts/private_dot_local/share/.jetbrains/.jetbrains.loadout.ts";
import { everydayCli, shellScripts } from "./shared.loadout.ts";

// Every Omarchy machine: Omarchy's own installer for system packages, brew
// where Arch's package lags behind (trash-cli, awscli, vim) or is another
// tool under the same name (Arch's yq is kislyuk's, not mikefarah's).
export const omarchyProfile = profile<Data>("omarchy", {
  data: { omarchy: true },
  install: [
    via(omarchy, [
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
    ]),
    via(flatpak, [flathubRemote, stremio]),
    via(omarchyAur, [antigravity, slack, teamsForLinux, anydesk, brave, openssl11]),
    omarchyPackageLists,
    variant(setupBrew, "linux"),
    variant(jetbrainsToolbox, "linux"),
    variant(tpack, "linux"),
    ngrok,
    intentional,
    via(brew, [just, vim, scrcpy, awscli, trashCli, yq]),
    via(brewTap, [workmux]),
    via(brewCask, [googleCloudCli]),
  ],
  run: [
    // claude comes from mise here (conf.d/omarchy.toml).
    dotfilesAll,
    setupGit,
    skillsRepo,
    workmuxSetup,
    defaultShell,
    nvimPlugins,
    masonKotlinLsp,
    removeKotlinLspDownload,
    removeLoadoutBunDownloads,
    unlinkBrewGlib,
    keychronLauncherAccess,
    shellScripts,
    // Each tool's default version now; the older ones and the rest later.
    args(miseTools, "node", "python", "neovim", "go"),
    miseToolsLater,
    miseDefaultPackages,
    args(omarchyDefaultAgent, "claude"),
    omarchyDefaultTerminal,
    tmuxPlugins,
    removeBrewTmux,
    omarchyTmuxTheme,
    linkJetbrainsLaunchersLinux,
    androidSdk,
    // Hyprland
    args(omarchyHyprConfig, "input", "looknfeel", "bindings"),
    omarchyCloseWindowKey,
    omarchyGoogleBindings,
    omarchyHarpoon,
    args(omarchyThemeMode, "tokyo-night", "catppuccin-latte"),
    omarchyBarFn(),
    omarchyWorkspaceLayoutMenu,
    // Apps the Omarchy way
    omarchy1password,
    onepasswordCli,
    omarchyVscode,
    omarchyBrave,
    args(omarchyDefaultBrowser, "brave"),
    removeSurfingkeys,
    args(omarchyAgentsPrune, "claude", "codex", "gh", "gemini"),
    // Web apps: Google's in HEY's place
    args(omarchyWebappsRemove, "Basecamp", "HEY"),
    omarchyWebappGmail,
    omarchyWebappGoogleCalendar,
    omarchyWebappClaude,
    omarchyCommandOverrides,
    omarchyKeyboardBacklightGuard,
    // The screensaver gets ~14 minutes (it starts at 150s) before the lock.
    args(omarchyIdle, "1000"),
    omarchyDefaultDictation,
    omarchyRemoveVoxtypeExtras,
    args(superwhisperSettings, "processing=offline", "language=auto"),
  ],
});
