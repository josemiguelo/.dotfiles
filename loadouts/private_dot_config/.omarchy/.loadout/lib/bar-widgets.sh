# Sourced by the scripts that read or change the Omarchy bar's widgets: their
# entries in Omarchy's bar layout (~/.config/omarchy/shell.json, bar.layout),
# and the settings a widget's file lists, set with `omarchy bar set` into its
# entry (keys the file doesn't list are left as they are).

BAR_JSON=$HOME/.config/omarchy/shell.json

# widget_enabled <id>: enabled as `omarchy plugin list` says. A bar widget
# counts as enabled only while it is on the bar.
widget_enabled() {
  omarchy plugin list --json 2>/dev/null | jq -e --arg id "$1" 'any(.[]; .id == $id and .enabled)' >/dev/null
}

# widget_on_bar <id>: in any section of the bar's layout.
widget_on_bar() {
  [ -f "$BAR_JSON" ] && jq -e --arg id "$1" '[.bar.layout[]?[]?.id] | index($id) != null' "$BAR_JSON" >/dev/null
}

# widget_configured <id> <settings-file>: every key the file lists has that
# value in the widget's entry. No file, nothing to check.
widget_configured() {
  [ -f "$2" ] || return 0
  [ -f "$BAR_JSON" ] && jq -e -n --arg id "$1" --slurpfile want "$2" --slurpfile shell "$BAR_JSON" '
    ([$shell[0].bar.layout[]?[]? | select(.id == $id)][0] // {}) as $entry
    | $want[0] | to_entries | all(.value == $entry[.key])' >/dev/null
}

# widget_configure <id> <settings-file>: sets every key the file lists.
widget_configure() {
  [ -f "$2" ] || return 0
  for key in $(jq -r 'keys[]' "$2"); do
    omarchy bar set "$1" "$key" "$(jq -c --arg k "$key" '.[$k]' "$2")" --json >/dev/null
  done
}
