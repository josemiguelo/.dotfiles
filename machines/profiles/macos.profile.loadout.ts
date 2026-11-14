import { brew, brewCask, profile, variant, via } from "loadout";
import type { Data } from "../data.ts";
import { setupGit } from "../../loadouts/.gitconfig/.git.loadout.ts";
import { claude, skillsRepo } from "../../loadouts/private_dot_claude/.claude.loadout.ts";
import { codex } from "../../loadouts/private_dot_codex/.codex.loadout.ts";
import { n1passwordCli } from "../../loadouts/private_dot_config/.1password/.1password.loadout.ts";
import { androidSdk } from "../../loadouts/private_dot_config/.android-sdk/.android-sdk.loadout.ts";
import { awscli } from "../../loadouts/private_dot_config/.awscli.loadout.ts";
import { azureCli } from "../../loadouts/private_dot_config/.azure-cli.loadout.ts";
import { coreutils } from "../../loadouts/private_dot_config/.coreutils.loadout.ts";
import { gawk } from "../../loadouts/private_dot_config/.gawk.loadout.ts";
import { gh } from "../../loadouts/private_dot_config/.gh.loadout.ts";
import { ghostscript } from "../../loadouts/private_dot_config/.ghostscript.loadout.ts";
import { gnuSed } from "../../loadouts/private_dot_config/.gnu-sed.loadout.ts";
import { brewTap, brewTapCask, setupBrew } from "../../loadouts/private_dot_config/.homebrew/.homebrew.loadout.ts";
import { jiraCli } from "../../loadouts/private_dot_config/.jira-cli.loadout.ts";
import { jordanbairdIce } from "../../loadouts/private_dot_config/.jordanbaird-ice.loadout.ts";
import { jq } from "../../loadouts/private_dot_config/.jq.loadout.ts";
import { removeLoadoutBunDownloads } from "../../loadouts/private_dot_config/.loadout-cli.loadout.ts";
import { lunar } from "../../loadouts/private_dot_config/.lunar.loadout.ts";
import { meetingbar } from "../../loadouts/private_dot_config/.meetingbar.loadout.ts";
import { obs } from "../../loadouts/private_dot_config/.obs.loadout.ts";
import { qemu } from "../../loadouts/private_dot_config/.qemu.loadout.ts";
import { scrcpy } from "../../loadouts/private_dot_config/.scrcpy.loadout.ts";
import { superwhisper } from "../../loadouts/private_dot_config/.superwhisper/.superwhisper.loadout.ts";
import { terraform } from "../../loadouts/private_dot_config/.terraform.loadout.ts";
import { trashCli } from "../../loadouts/private_dot_config/.trash-cli.loadout.ts";
import { tree } from "../../loadouts/private_dot_config/.tree.loadout.ts";
import { tryProgram } from "../../loadouts/private_dot_config/.try.loadout.ts";
import { unixodbc } from "../../loadouts/private_dot_config/.unixodbc.loadout.ts";
import { wget } from "../../loadouts/private_dot_config/.wget.loadout.ts";
import { yq } from "../../loadouts/private_dot_config/.yq.loadout.ts";
import { chezmoi, dotfilesAll } from "../../loadouts/private_dot_config/chezmoi/.chezmoi.loadout.ts";
import { kitty } from "../../loadouts/private_dot_config/kitty/.kitty.loadout.ts";
import { javaMacosIntegration, mise, miseDefaultPackages, miseTools } from "../../loadouts/private_dot_config/mise/.mise.loadout.ts";
import { masonKotlinLsp, nvimPlugins, removeKotlinLspDownload } from "../../loadouts/private_dot_config/nvim/.nvim.loadout.ts";
import { ngrok } from "../../loadouts/private_dot_config/private_ngrok/.ngrok.loadout.ts";
import { raycast } from "../../loadouts/private_dot_config/raycast/.raycast.loadout.ts";
import { tmux, tmuxPlugins, tpack } from "../../loadouts/private_dot_config/tmux/.tmux.loadout.ts";
import { workmux, workmuxSetup } from "../../loadouts/private_dot_config/workmux/.workmux.loadout.ts";
import { downloadFonts } from "../../loadouts/private_dot_local/share/.fonts/.fonts.loadout.ts";
import { everydayCli, shellScripts } from "./shared.loadout.ts";

// Every macOS machine. macOS ships zsh as the login shell, so zsh is neither
// installed nor switched to.
export const macos = profile<Data>("macos", {
  spare: "the work laptop extends it, from a private child repo of this one",
  install: [
    variant(setupBrew, "macos"),
    ngrok,
    claude,
    via(brew, [
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
    ]),
    via(brewTap, [workmux, terraform]),
    via(brewCask, [kitty, n1passwordCli, raycast, codex, jordanbairdIce, lunar, meetingbar, obs, superwhisper]),
    via(brewTapCask, [tpack]),
  ],
  run: [
    dotfilesAll,
    setupGit,
    skillsRepo,
    workmuxSetup,
    nvimPlugins,
    masonKotlinLsp,
    removeKotlinLspDownload,
    removeLoadoutBunDownloads,
    downloadFonts,
    shellScripts,
    miseTools,
    miseDefaultPackages,
    javaMacosIntegration,
    androidSdk,
    tmuxPlugins,
  ],
});
