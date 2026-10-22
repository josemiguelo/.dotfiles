// Command-line tools with nothing beside them. A tool that gains a script
// or a config moves to its own folder.
package repo

import loadout.dsl.*

// ─── Everyday shell tools: brew on macOS, Omarchy's packages on Omarchy ───

val atuin = program(name = "atuin") {
    installVia(
        brew,
        omarchy,
    )
}

val bat = program(name = "bat") {
    installVia(
        brew,
        omarchy,
    )
}

val eza = program(name = "eza") {
    installVia(
        brew,
        omarchy,
    )
}

val fd = program(name = "fd") {
    installVia(
        brew,
        omarchy,
    )
}

val gitDelta = program(name = "git-delta") {
    installVia(
        brew,
        omarchy,
    )
}

val lazydocker = program(name = "lazydocker") {
    installVia(
        brew,
        omarchy,
    )
}

val lazygit = program(name = "lazygit") {
    installVia(
        brew,
        omarchy,
    )
}

val ripgrep = program(name = "ripgrep") {
    installVia(
        brew,
        omarchy,
    )
}

val treeSitterCli = program(name = "tree-sitter-cli") {
    installVia(
        brew,
        omarchy,
    )
}

val zoxide = program(name = "zoxide") {
    installVia(
        brew,
        omarchy,
    )
}

/** The shell prompt; its config is configs/private_dot_config/starship.toml, one file among others'. */
val starship = program(name = "starship") {
    installVia(
        brew,
        omarchy,
    )
}

/** charmbracelet's gum (the dotfiles' gclone and workmux wrappers use it); an Omarchy base package. */
val gum = program(name = "gum") {
    installVia(
        brew,
        omarchy,
    )
}

// ─── brew only: one variant, so a machine maps them without naming it ───

val awscli = program(name = "awscli") {
    installVia(
        brew,
    )
}

val azureCli = program(
    name = "azure-cli",
    description = "Azure CLI",
) {
    installVia(
        brew,
    )
}

val gh = program(
    name = "gh",
    description = "GitHub CLI",
) {
    installVia(
        brew,
    )
}

val jiraCli = program(
    name = "jira-cli",
    description = "Jira CLI",
) {
    installVia(
        brew,
    )
}

val jq = program(name = "jq") {
    installVia(
        brew,
    )
}

val qemu = program(name = "qemu") {
    installVia(
        brew,
    )
}

val trashCli = program(name = "trash-cli") {
    installVia(
        brew,
    )
}

val tree = program(name = "tree") {
    installVia(
        brew,
    )
}

val tryCli = program(
    name = "try",
    description = "ephemeral workspace manager",
) {
    installVia(
        brew,
    )
}

val wget = program(name = "wget") {
    installVia(
        brew,
    )
}

val yq = program(name = "yq") {
    installVia(
        brew,
    )
}

/** usql (the cobranded bootstrap-env.sh) links against it at a fixed path; without it usql dies with a dyld error. */
val unixodbc = program(name = "unixodbc") {
    installVia(
        brew,
    )
}

// macOS ships BSD tools; scripts written for GNU's need these.
val coreutils = program(name = "coreutils") {
    installVia(
        brew,
    )
}

val gawk = program(name = "gawk") {
    installVia(
        brew,
    )
}

val gnuSed = program(name = "gnu-sed") {
    installVia(
        brew,
    )
}

/** OpenAI's Codex CLI: a cask on macOS; on Omarchy it comes from mise, so it isn't mapped there. */
val codex = program(
    name = "codex",
    description = "OpenAI Codex CLI",
) {
    installVia(
        brewCask,
    )
}

// ─── Different package per mechanism ───

val just = program(name = "just") {
    installVia(
        brew,
        dnf,
    )
}

// Fedora's full vim is vim-enhanced (vim-minimal is the stub); Homebrew's
// formula is vim.
val vim = program(name = "vim") {
    installVia(
        dnf(pkg = "vim-enhanced"),
        brew,
    )
}

val googleCloudCli = program(
    name = "google-cloud-cli",
    description = "Google Cloud CLI",
) {
    installVia(
        dnfRepo(repofile = file("google-cloud-cli.repo")),
        // Homebrew's cask downloads the Linux tarball on Linux; on Arch the CLI
        // is AUR-only.
        brewCask(pkg = "gcloud-cli"),
    )
}

// HashiCorp pulled terraform from homebrew-core over licensing (BSL); it
// ships only from their own tap now.
val terraform = program(
    name = "terraform",
    description = "HashiCorp Terraform",
) {
    installVia(
        tap(tap = "hashicorp/tap"),
    )
}
