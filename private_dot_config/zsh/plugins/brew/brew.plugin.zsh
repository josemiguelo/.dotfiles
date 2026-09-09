# still load brew since it can be used on several platforms
# `brew shellenv` is a bash script and costs ~25ms to fork; its output only
# changes when brew itself does, so serve it from a cache
[[ -x /opt/homebrew/bin/brew ]] && zcache brew /opt/homebrew/bin/brew shellenv
