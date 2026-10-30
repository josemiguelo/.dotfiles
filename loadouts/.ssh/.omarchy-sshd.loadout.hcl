# ssh on Omarchy: the ssh server, set up Omarchy's way.

# sshd the Omarchy way (rate-limited ufw rule from private ranges, key-only
# logins); authorized_keys mirrors the account's keys with the named titles.
script "omarchy-sshd" {
  description = "sshd with key-only logins for the trusted GitHub keys"
  managed_by  = ".loadout/omarchy-sshd.sh"
  needs_sudo  = true

  # gh logged in, with the scope that lists the account's keys.
  run_after = [script.github-ssh-key]
}
