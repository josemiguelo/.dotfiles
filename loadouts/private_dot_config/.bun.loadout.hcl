# Bun: what loadout's scripts run with (`#!/usr/bin/env bun`), so every machine
# that runs them has it. A program, so it's there before any script runs; on
# a fresh Mac, scripts find brew's through setup-brew's `provides "brew"`.
program "bun" {
  install_via = [omarchy, brew]
}
