# flatpak: the package itself and Flathub as a user-level remote
# (~/.local/share/flatpak). Every flatpak install `requires` both, so they
# come first.

# Fedora ships it; Omarchy doesn't.
program "flatpak" {
  description = "flatpak app runtime"

  # So a plan installing it may install flatpaks after it.
  via "dnf" {
    provides "flatpak" {}
  }

  via "omarchy" {
    provides "flatpak" {}
  }
}

# Flathub as a user-level remote, so flatpaks can depend on it.
program "flathub-remote" {
  description = "flathub flatpak remote (user)"

  # A remote, not an app: the probe comes from flatpak, the rest is its own.
  via "flatpak" {
    command    = "flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
    present    = "x=$(flatpak --user remotes --columns=name) && printf '%s\\n' \"$x\" | grep -qx flathub"
  }
}

requires "flatpak" { programs = [program.flatpak, program.flathub-remote] }
