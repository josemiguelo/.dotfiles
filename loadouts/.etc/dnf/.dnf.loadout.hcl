# dnf: its config before any dnf install, and the plugins its COPR
# mechanism needs. Every dnf installer `requires` setup-dnf, so it runs
# before any dnf install.

program "setup-dnf" {
  description = "dnf.conf performance and behavior tweaks"

  via "dnf" {
    managed_by = ".loadout/setup-dnf.sh"
    needs_sudo = true
  }
}

# Provides the copr command the dnf-copr mechanism runs.
program "dnf-plugins-core" {
  description = "dnf plugins (provides the copr command)"
  install_via = [dnf]
}

# Every dnf install waits for dnf.conf; setup-dnf, itself a dnf
# variant, is exempt from its own rule.
requires "dnf" { programs = [program.setup-dnf] }
requires "dnf-repo" { programs = [program.setup-dnf] }
# kitty no longer says it needs dnf-plugins-core.
requires "dnf-copr" { programs = [program.setup-dnf, program.dnf-plugins-core] }
