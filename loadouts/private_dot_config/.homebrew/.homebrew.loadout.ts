// Homebrew: brew itself, and third-party taps. brew.ts, setup-brew.ts and
// brew-taps.ts are in .loadout/. brew and brew-cask are loadout's own.
import { brew, brewCask, custom, installer, program, requires, runScript } from "loadout";
import { git } from "../../.gitconfig/.git.loadout.ts";
import { curl } from "../.curl.loadout.ts";
import { gcc } from "../.gcc.loadout.ts";
import { procpsNg } from "../.procps-ng.loadout.ts";

// Homebrew must exist and be writable by the login user before anything
// installs with brew. Homebrew is single-owner: a prefix installed by
// another account fails every `brew install`, so the Linux script reclaims
// it. PATH is not touched here: brew reaches interactive shells via the zsh
// plugin, and loadout's brew commands via `provides`'s `at`, which restates
// brew-prefix.sh's prefix (loadout can't source it): change both together.
export const setupBrew = program("setup-brew", {
  description: "Homebrew installed and owned by the login user",
  install: [
    // Linux: /home/linuxbrew, reclaimed for the login user, after Homebrew's
    // own build prerequisites.
    custom("linux", {
        managedBy: ".loadout/setup-brew.ts",
        needsSudo: true,
        dependsOn: [curl, git, gcc, procpsNg],
        provides: { brew: { at: "/home/linuxbrew/.linuxbrew/bin" } },
      }),
    // macOS: the official installer into /opt/homebrew, with Xcode's command
    // line tools. NONINTERACTIVE=1 makes it run `sudo -n`, which fails without
    // cached credentials: needsSudo has loadout ask for the password first.
    custom("macos", {
        command: 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"',
        needsSudo: true,
        version: runScript(".loadout/brew.ts --version"),
        regex: "Homebrew ([0-9][0-9.]*)",
        provides: { brew: { at: "/opt/homebrew/bin" } },
      }),
  ],
});

export const outdatedAwk = "awk '{n=$1; sub(/.*[/]/, \"\", n); v=$NF; gsub(/[()]/, \"\", v); print n, v}'";

// A formula or cask from a third-party tap: tapped and trusted (trust is per
// user), then installed by its full path, `<tap>/<pkg>`. pkg stays the bare
// name, which is what `brew list` and the outdated oracle report. The rest
// is the built-ins', brew found the same way (setup-brew's `provides`), so
// `loadout upgrade` runs one `brew upgrade` for brew and brew-tap. A program
// names its tap: via(brewTap, { params: { tap: "hashicorp/tap" } }).
export const brewTap = installer("brew-tap", {
  params: ["tap"],
  probe: "brew",
  install: runScript(".loadout/brew-taps.ts install {tap} {tap}/{pkg}"),
  upgrade: "brew upgrade",
  check: "brew list --versions {pkg}",
  outdatedAll: `HOMEBREW_NO_AUTO_UPDATE=1 brew outdated --verbose | ${outdatedAwk}`,
});

export const brewTapCask = installer("brew-tap-cask", {
  params: ["tap"],
  probe: "brew",
  install: runScript(".loadout/brew-taps.ts install {tap} {tap}/{pkg} --cask"),
  upgrade: "brew upgrade --cask",
  check: "brew list --cask --versions {pkg}",
  outdatedAll: `HOMEBREW_NO_AUTO_UPDATE=1 brew outdated --cask --verbose | ${outdatedAwk}`,
});

// Homebrew must exist and be writable by the login user first.
requires(brew, [setupBrew]);

requires(brewCask, [setupBrew]);

requires(brewTap, [setupBrew]);

requires(brewTapCask, [setupBrew]);
