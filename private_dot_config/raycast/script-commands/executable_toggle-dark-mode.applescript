#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle System Appearance
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🌚
# @raycast.packageName Developer Utils

# Documentation:
# @raycast.description Toggle System Appearance
# @raycast.author josemiguelo

tell application "System Events"
	tell appearance preferences
		set dark mode to not dark mode
	end tell
end tell

set scriptPath to "/Users/jochoa/.local/bin/toggle_wezterm_theme"
set shellCommand to quoted form of scriptPath

try
	set shellResult to do shell script shellCommand
	log "Toggle dark mode on wezterm!"
on error errMsg number errNum
	log "Error toggling dark mode on wezterm!"
end try

