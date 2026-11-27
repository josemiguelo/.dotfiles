import { profile, withBrew, withBrewCask } from "loadout";
import type { Data } from "../data.ts";
import { setupGit } from "../../loadouts/git/git.loadout.ts";
import { claude, skillsRepo } from "../../loadouts/claude/claude.loadout.ts";
import { codex } from "../../loadouts/codex/codex.loadout.ts";
import { n1passwordCli } from "../../loadouts/1password/1password.loadout.ts";
import { androidSdk } from "../../loadouts/android-sdk/android-sdk.loadout.ts";
import { awscli } from "../../loadouts/awscli/awscli.loadout.ts";
import { azureCli } from "../../loadouts/azure-cli/azure-cli.loadout.ts";
import { coreutils } from "../../loadouts/coreutils/coreutils.loadout.ts";
import { gawk } from "../../loadouts/gawk/gawk.loadout.ts";
import { gh } from "../../loadouts/gh/gh.loadout.ts";
import { ghostscript } from "../../loadouts/ghostscript/ghostscript.loadout.ts";
import { gnuSed } from "../../loadouts/gnu-sed/gnu-sed.loadout.ts";
import { withBrewTap, withBrewTapCask, setupBrew } from "../../loadouts/homebrew/homebrew.loadout.ts";
import { jiraCli } from "../../loadouts/jira-cli/jira-cli.loadout.ts";
import { jordanbairdIce } from "../../loadouts/jordanbaird-ice/jordanbaird-ice.loadout.ts";
import { jq } from "../../loadouts/jq/jq.loadout.ts";
import { lunar } from "../../loadouts/lunar/lunar.loadout.ts";
import { meetingbar } from "../../loadouts/meetingbar/meetingbar.loadout.ts";
import { obs } from "../../loadouts/obs/obs.loadout.ts";
import { qemu } from "../../loadouts/qemu/qemu.loadout.ts";
import { scrcpy } from "../../loadouts/scrcpy/scrcpy.loadout.ts";
import { superwhisper } from "../../loadouts/superwhisper/superwhisper.loadout.ts";
import { terraform } from "../../loadouts/terraform/terraform.loadout.ts";
import { trashCli } from "../../loadouts/trash-cli/trash-cli.loadout.ts";
import { tree } from "../../loadouts/tree/tree.loadout.ts";
import { tryProgram } from "../../loadouts/try/try.loadout.ts";
import { unixodbc } from "../../loadouts/unixodbc/unixodbc.loadout.ts";
import { wget } from "../../loadouts/wget/wget.loadout.ts";
import { yq } from "../../loadouts/yq/yq.loadout.ts";
import { chezmoi, dotfilesAll } from "../../loadouts/chezmoi/chezmoi.loadout.ts";
import { kitty } from "../../loadouts/kitty/kitty.loadout.ts";
import { javaMacosIntegration, mise, miseDefaultPackages, miseTools, miseToolsLater } from "../../loadouts/mise/mise.loadout.ts";
import { masonKotlinLsp, nvimPlugins } from "../../loadouts/nvim/nvim.loadout.ts";
import { ngrok } from "../../loadouts/ngrok/ngrok.loadout.ts";
import { raycast } from "../../loadouts/raycast/raycast.loadout.ts";
import { tmux, tmuxPlugins, tpack } from "../../loadouts/tmux/tmux.loadout.ts";
import { workmux, workmuxSetup } from "../../loadouts/workmux/workmux.loadout.ts";
import { downloadFonts } from "../../loadouts/fonts/fonts.loadout.ts";
import { everydayCli, shellScripts } from "./shared.loadout.ts";

// Every macOS machine. macOS ships zsh as the login shell, so zsh is neither
// installed nor switched to.
export const macos = profile<Data>("macos", {
  keepUnused: "the work laptop extends it, from a private child repo of this one",
  install: [
    setupBrew("macos"),
    ngrok,
    claude,
    withBrew(
      everydayCli,
      scrcpy,
      chezmoi,
      mise,
      tmux,
      awscli,
      trashCli,
      yq,
      azureCli,
      coreutils,
      gawk,
      gh,
      ghostscript,
      gnuSed,
      jiraCli,
      jq,
      qemu,
      tree,
      unixodbc,
      wget,
      tryProgram,
    ),
    withBrewTap(workmux, terraform),
    withBrewCask(kitty, n1passwordCli, raycast, codex, jordanbairdIce, lunar, meetingbar, obs, superwhisper),
    withBrewTapCask(tpack),
  ],
  run: [
    dotfilesAll,
    setupGit,
    skillsRepo,
    workmuxSetup,
    nvimPlugins,
    masonKotlinLsp,
    downloadFonts,
    shellScripts,
    // Java's default too: java-macos-integration (core: it asks for sudo)
    // registers the JDKs there are, and the older ones come later, registered
    // the next time it runs.
    miseTools({ tools: ["node", "python", "neovim", "go", "java"] }),
    miseToolsLater,
    miseDefaultPackages,
    javaMacosIntegration,
    androidSdk,
    tmuxPlugins,
  ],
});
