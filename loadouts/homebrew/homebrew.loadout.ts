// Homebrew: brew itself, and third-party taps. brew.ts, setup-brew.ts and
// brew-taps.ts are in .loadout/. brew and brew-cask are loadout's own.
import { installer, program, runFile, withBrew, withBrewCask, withCustomSteps } from "loadout";
import { git } from "../git/git.loadout.ts";
import { curl } from "../curl/curl.loadout.ts";
import { gcc } from "../gcc/gcc.loadout.ts";
import { procpsNg } from "../procps-ng/procps-ng.loadout.ts";

// Homebrew must exist and be writable by the login user before anything
// installs with brew. Homebrew is single-owner: a prefix installed by
// another account fails every `brew install`, so the Linux script reclaims
// it. PATH is not touched here: brew reaches interactive shells via the zsh
// plugin, and loadout's brew commands via `addsToPath`, which restates
// brew-prefix.sh's prefix (loadout can't source it): change both together.
export const setupBrew = program("setup-brew", {
  description: "Homebrew installed and owned by the login user",
  canBeInstalled: [
    // Linux: /home/linuxbrew, reclaimed for the login user, after Homebrew's
    // own build prerequisites.
    withCustomSteps("linux", {
        module: () => import("./.loadout/setup-brew.ts"),
        needsSudo: true,
        dependsOn: [curl, git, gcc, procpsNg],
        addsToPath: { brew: "/home/linuxbrew/.linuxbrew/bin" },
      }),
    // macOS: the official installer into /opt/homebrew, with Xcode's command
    // line tools. NONINTERACTIVE=1 makes it run `sudo -n`, which fails without
    // cached credentials: needsSudo has loadout ask for the password first.
    withCustomSteps("macos", {
        installCommand: 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"',
        needsSudo: true,
        versionCommand: runFile(".loadout/brew.ts", "--version"),
        versionRegex: /Homebrew ([0-9][0-9.]*)/,
        addsToPath: { brew: "/opt/homebrew/bin" },
      }),
  ],
});

export const outdatedAwk = "awk '{n=$1; sub(/.*[/]/, \"\", n); v=$NF; gsub(/[()]/, \"\", v); print n, v}'";

// A formula or cask from a third-party tap: tapped and trusted (trust is per
// user), then installed by its full path, `<tap>/<package>`. The package name stays the bare
// name, which is what `brew list` and the outdated oracle report. The rest
// is the built-ins', brew found the same way (setup-brew's `addsToPath`), so
// `loadout installer upgrade` runs one `brew upgrade` for brew and brew-tap. A program
// names its tap: withBrewTap({ tap: "hashicorp/tap" }).
export const withBrewTap = installer("brew-tap", {
  installerParams: ["tap"],
  neededBinary: "brew",
  installCommand: runFile(".loadout/brew-taps.ts", "install", "{tap}", "{tap}/{packageName}"),
  upgradeCommand: "brew upgrade",
  checkCommand: "brew list --versions {packageName}",
  allOutdatedCommand: `HOMEBREW_NO_AUTO_UPDATE=1 brew outdated --verbose | ${outdatedAwk}`,
});

export const withBrewTapCask = installer("brew-tap-cask", {
  installerParams: ["tap"],
  neededBinary: "brew",
  installCommand: runFile(".loadout/brew-taps.ts", "install", "{tap}", "{tap}/{packageName}", "--cask"),
  upgradeCommand: "brew upgrade --cask",
  checkCommand: "brew list --cask --versions {packageName}",
  allOutdatedCommand: `HOMEBREW_NO_AUTO_UPDATE=1 brew outdated --cask --verbose | ${outdatedAwk}`,
});

// Homebrew must exist and be writable by the login user first.
withBrew.needs(setupBrew);

withBrewCask.needs(setupBrew);

withBrewTap.needs(setupBrew);

withBrewTapCask.needs(setupBrew);
