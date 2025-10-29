#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title New wezterm workspace
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🖥️
# @raycast.packageName Developer Utils

# Documentation:
# @raycast.description Open a new wezterm workspace
# @raycast.author josemiguelo

wezterm start --always-new-process
