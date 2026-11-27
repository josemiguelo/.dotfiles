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

