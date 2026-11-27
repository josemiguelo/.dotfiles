// mise: the tool-version manager, the tools config.toml pins, the default
// packages inside them, and what depends on those tools.
import { program, script, withBrew, withOmarchy, withOmarchyAur } from "loadout";

export const mise = program("mise", {
  description: "mise tool-version manager",
  canBeInstalled: [
    // On Omarchy, Omarchy's own mise-bin, ahead of Arch's extra/mise.
    withOmarchy({ packageName: "mise-bin" }),
    withBrew,
  ],
});

// What mise installs inside itself, and what builds on it: `run: [miseTools]`.

// Exactly the versions config.toml pins; and whether those pins are behind
// upstream.
// OpenSSL 1.1 beside the system's: Python 2.7's ssl module builds against
// 1.x only, and Arch dropped 1.1 from its repos. tools.ts builds the 2.x
// pythons config.toml pins against it. The AUR builds it from source, and
// makepkg's defaults (one core, check() running OpenSSL's whole test suite)
// make that the slowest step of a new machine: on every core and without the
// tests it takes about two minutes.
export const openssl11 = program("openssl-1.1", {
  description: "OpenSSL 1.1, for mise's Python 2.7 builds",
  canWait: "built from source, for mise's Python 2.7 alone",
  canBeInstalled: [withOmarchyAur({ installCommand: 'MAKEFLAGS="-j$(nproc)" yay -S --noconfirm --needed --mflags --nocheck openssl-1.1' })],
});

// Named by the machine (`miseTools({ tools: ["node"] })`), only
// those tools' default versions: setup's core, with mise-tools-later bringing
// the rest. Without names, every version.
export const miseTools = script("mise-tools", {
  description: "mise tools at the versions ~/.config/mise/config.toml pins",
  module: () => import("./.loadout/tools.ts"),
  rules: () => import("./.loadout/tools.rules.ts"),
  runAfter: [mise],
  updates: () => import("./.loadout/outdated-tools.ts"),
});

// Everything mise-tools' names left out: older versions, tools nothing in
// setup needs, and Python 2.7's build from source against openssl-1.1.
export const miseToolsLater = script("mise-tools-later", {
  description: "the rest of the mise tools config.toml pins",
  canWait: "older versions and builds from source; setup needs none of them",
  module: () => import("./.loadout/tools.ts"),
  rules: () => import("./.loadout/tools.rules.ts"),
  runAfter: [miseTools, openssl11],
});

// mise seeds default packages only into versions it installs later; this
// backfills every one.
export const miseDefaultPackages = script("mise-default-packages", {
  description: "default npm/gem packages in every mise node/ruby version",
  module: () => import("./.loadout/default-packages.ts"),
  runAfter: [miseTools],
});

// mise's JDKs registered in /Library/Java/JavaVirtualMachines, as
// asdf-java's macOS integration did. The macos profile runs it.
export const javaMacosIntegration = script("java-macos-integration", {
  description: "mise's JDKs registered with macOS (java_home)",
  module: () => import("./.loadout/java-macos.ts"),
  needsSudo: true,
  runAfter: [miseTools],
});

// The coding agent Omarchy's keybinding and menu launch (it comes from mise),
// named by the machine: `omarchyDefaultAgent({ agent: "claude" })`.
export const omarchyDefaultAgent = script("omarchy-default-agent", {
  description: "Omarchy's default coding agent",
  module: () => import("./.loadout/default-agent.ts"),
  rules: () => import("./.loadout/default-agent.rules.ts"),
  runAfter: [miseTools],
});
