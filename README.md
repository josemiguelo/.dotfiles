# .dotfiles

My machines in one repo: the dotfiles ([chezmoi](https://www.chezmoi.io/)
reads `loadouts/`) and everything [loadout](https://github.com/josemiguelo/loadout)
installs, maintains and keeps applied.

## New machine

One command, on a fresh Omarchy, macOS or Fedora install:

```bash
curl -fsSL https://raw.githubusercontent.com/josemiguelo/.dotfiles/master/bootstrap.sh | sh -s -- <machine>
```

`<machine>` names a machine of the repo (`machines/<machine>.loadout.hcl`)
and becomes the hostname (each install keeps its own state file, so a reinstall gets a name of its own, e.g.
`t2-macbook-omarchy-2`). The work laptop is a private child repo's machine
(loadout's contract 18): `bootstrap.sh <machine> --child <ssh url>` keeps its
hostname, clones the child, and sets it up from there. [`bootstrap.sh`](bootstrap.sh) installs git and
chezmoi, sets the hostname, applies the dotfiles over https, installs loadout
and runs `loadout setup-new-machine`; `--dry-run` prints the commands
instead. What it asks for: the sudo password and, once, a GitHub login in the
browser (`github-ssh-key` adds this machine's new ssh key, made without a
passphrase by `setup-ssh`, to the account). Reboot when it's done.

On a fresh Omarchy, run `omarchy update` (or at least `sudo pacman -Sy`)
first: the install leaves pacman without package lists, and installing
chezmoi fails with "target not found".

A machine new to the repo is declared first, compiled and pushed before the
bootstrap reads it: `machine "<machine>" { extends = [profile.t2-macbook] }`
(or `profile.omarchy`, `profile.macos`, `profile.fedora`) in `machines/<machine>.loadout.hcl`,
then `loadout compile` and commit the lock with it. `loadout sync` publishes its state
afterwards (it commits only the state file). To ssh into the T2 laptop from it,
add its name to the key titles `omarchy-sshd` trusts in
`machines/profiles/t2-macbook.profile.loadout.hcl`: the T2 lets in no other key.
