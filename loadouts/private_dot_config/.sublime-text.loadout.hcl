# Versions are build numbers (4192). The vendor publishes a per-arch .repo;
# the shell running the install expands $(uname -m).
program "sublime-text" {
  description = "Sublime Text editor"

  via "dnf-repo" {
    params = { repofile = "https://download.sublimetext.com/rpm/stable/$(uname -m)/sublime-text.repo" }
    regex  = "([0-9]+)"
  }

  # pacman's version is "4.<build>", which the dotted regex reads whole.
  via "omarchy" { pkg = "sublime-text-4" }
}
