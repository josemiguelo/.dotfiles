# main_checkout_path <file>: <file>'s path in its repo's main checkout, for a
# script that writes its own path into a file outside the repo (an Omarchy
# hook, a command wrapper). Run from a feature worktree, its own path dies
# with the worktree once the feature merges, and the hook then fails
# silently on every call. The cost: while a feature is tried, the hook runs
# master's copy of the script, not the feature's (AGENTS.md, "Feature
# worktrees"). <file> as an absolute path when it isn't in a
# worktree, or when the main checkout has no copy yet (a script new to the
# feature): loadout's check, run from the main checkout after the merge,
# sees the path differ and installs again.
main_checkout_path() {
  _mcp_dir=$(cd "$(dirname "$1")" && pwd -P)
  _mcp_file=$_mcp_dir/$(basename "$1")
  if _mcp_top=$(git -C "$_mcp_dir" rev-parse --show-toplevel 2>/dev/null) &&
    _mcp_common=$(git -C "$_mcp_dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) &&
    # A non-bare main checkout keeps the common git dir as its .git.
    [ "$(basename "$_mcp_common")" = .git ] &&
    [ -f "$(dirname "$_mcp_common")${_mcp_file#"$_mcp_top"}" ]; then
    echo "$(dirname "$_mcp_common")${_mcp_file#"$_mcp_top"}"
  else
    echo "$_mcp_file"
  fi
}
