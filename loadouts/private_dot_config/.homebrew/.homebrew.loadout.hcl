# Homebrew: brew itself, and third-party taps. brew.sh, setup-brew.sh and
# brew-taps.sh are in .loadout/. brew and brew-cask are loadout's own.

# Homebrew must exist and be writable by the login user before anything
# installs with brew. Homebrew is single-owner: a prefix installed by
# another account fails every `brew install`, so the Linux script reclaims
# it. PATH is not touched here: brew reaches interactive shells via the zsh
# plugin, and loadout's brew commands via `provides`'s `at`, which restates
# brew-prefix.sh's prefix (loadout can't source it): change both together.
program "setup-brew" {
  description = "Homebrew installed and owned by the login user"

  # Linux: /home/linuxbrew, reclaimed for the login user, after Homebrew's
  # own build prerequisites.
  custom "linux" {
    managed_by = ".loadout/setup-brew.sh"
    needs_sudo = true
    depends_on = [program.curl, program.git, program.gcc, program.procps-ng]
    provides "brew" {
      at = "/home/linuxbrew/.linuxbrew/bin"
    }
  }

  # macOS: the official installer into /opt/homebrew, with Xcode's command
  # line tools. NONINTERACTIVE=1 makes it run `sudo -n`, which fails without
  # cached credentials: needs_sudo has loadout ask for the password first.
  custom "macos" {
    command    = "NONINTERACTIVE=1 /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    needs_sudo = true
    version    = run_script(".loadout/brew.sh --version")
    regex      = "Homebrew ([0-9][0-9.]*)"
    provides "brew" {
      at = "/opt/homebrew/bin"
    }
  }
}

locals {
  outdated_awk = "awk '{n=$1; sub(/.*[/]/, \"\", n); v=$NF; gsub(/[()]/, \"\", v); print n, v}'"
}

# A formula or cask from a third-party tap: tapped and trusted (trust is per
# user), then installed by its full path, `<tap>/<pkg>`. pkg stays the bare
# name, which is what `brew list` and the outdated oracle report. The rest
# is the built-ins', brew found the same way (setup-brew's `provides`), so
# `loadout upgrade` runs one `brew upgrade` for brew and brew-tap. A program
# names its tap: via "brew-tap" { params = { tap = "hashicorp/tap" } }.
installer "brew-tap" {
  params       = ["tap"]
  probe        = "brew"
  install      = run_script(".loadout/brew-taps.sh install {tap} {tap}/{pkg}")
  upgrade      = "brew upgrade"
  check        = "brew list --versions {pkg}"
  outdated_all = "HOMEBREW_NO_AUTO_UPDATE=1 brew outdated --verbose | ${local.outdated_awk}"
}

installer "brew-tap-cask" {
  params       = ["tap"]
  probe        = "brew"
  install      = run_script(".loadout/brew-taps.sh install {tap} {tap}/{pkg} --cask")
  upgrade      = "brew upgrade --cask"
  check        = "brew list --cask --versions {pkg}"
  outdated_all = "HOMEBREW_NO_AUTO_UPDATE=1 brew outdated --cask --verbose | ${local.outdated_awk}"
}

# Homebrew must exist and be writable by the login user first.
requires "brew" { programs = [program.setup-brew] }
requires "brew-cask" { programs = [program.setup-brew] }
requires "brew-tap" { programs = [program.setup-brew] }
requires "brew-tap-cask" { programs = [program.setup-brew] }
