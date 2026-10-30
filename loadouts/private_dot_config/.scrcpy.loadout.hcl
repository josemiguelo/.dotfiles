program "scrcpy" {
  description = "scrcpy Android screen mirroring"
  install_via = [brew]

  via "dnf-copr" {
    params = { copr = "zeno/scrcpy" }
  }
}
