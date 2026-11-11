program "scrcpy" {
  description = "scrcpy Android screen mirroring"
  later       = "a large Homebrew install; nothing in setup needs it"
  via "brew" {}

  via "dnf-copr" {
    params = { copr = "zeno/scrcpy" }
  }
}
