// mise: the tool-version manager, the tools config.toml pins, the default
// packages inside them, and what depends on those tools.
import { brew, omarchy, omarchyAur, program, script, via } from "loadout";

export const mise = program("mise", {
  description: "mise tool-version manager",
  install: [
    // On Omarchy, Omarchy's own mise-bin, ahead of Arch's extra/mise.
    via(omarchy, { pkg: "mise-bin" }),
    brew,
  ],
});

// What mise installs inside itself, and what builds on it: `run: [miseTools]`.

// Exactly the versions config.toml pins; and whether those pins are behind
// upstream.
// OpenSSL 1.1 beside the system's: Python 2.7's ssl module builds against
// 1.x only, and Arch dropped 1.1 from its repos. tools.ts builds the 2.x
// pythons config.toml pins against it.
export const openssl11 = program("openssl-1.1", {
  description: "OpenSSL 1.1, for mise's Python 2.7 builds",
  later: "built from source, for mise's Python 2.7 alone",
  install: [omarchyAur],
});

// Named by the machine (`args(miseTools, "node", "python")`), only
// those tools' default versions: setup's core, with mise-tools-later bringing
// the rest. Without names, every version (macOS).
export const miseTools = script("mise-tools", {
  description: "mise tools at the versions ~/.config/mise/config.toml pins",
  managedBy: ".loadout/tools.ts",
  runAfter: [mise],
  updatesManagedBy: ".loadout/outdated-tools.ts",
});

// Everything mise-tools' names left out: older versions, tools nothing in
// setup needs, and Python 2.7's build from source against openssl-1.1.
export const miseToolsLater = script("mise-tools-later", {
  description: "the rest of the mise tools config.toml pins",
  later: "older versions and builds from source; setup needs none of them",
  managedBy: ".loadout/tools.ts",
  runAfter: [miseTools, openssl11],
});

// mise seeds default packages only into versions it installs later; this
// backfills every one.
export const miseDefaultPackages = script("mise-default-packages", {
  description: "default npm/gem packages in every mise node/ruby version",
  managedBy: ".loadout/default-packages.ts",
  runAfter: [miseTools],
});

// mise's JDKs registered in /Library/Java/JavaVirtualMachines, as
// asdf-java's macOS integration did. The macos profile runs it.
export const javaMacosIntegration = script("java-macos-integration", {
  description: "mise's JDKs registered with macOS (java_home)",
  managedBy: ".loadout/java-macos.ts",
  needsSudo: true,
  runAfter: [miseTools],
});

// The coding agent Omarchy's keybinding and menu launch (it comes from mise),
// named by the machine: `args(omarchyDefaultAgent, "claude")`.
export const omarchyDefaultAgent = script("omarchy-default-agent", {
  description: "Omarchy's default coding agent",
  file: ".loadout/default-agent.ts",
  check: 'test "$(omarchy default agent)" = "$1"',
  runAfter: [miseTools],
});
