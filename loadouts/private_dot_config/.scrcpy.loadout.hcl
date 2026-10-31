program "scrcpy" {
  description = "scrcpy Android screen mirroring"
  via "brew" {}

  via "dnf-copr" {
    params = { copr = "zeno/scrcpy" }
  }
}
