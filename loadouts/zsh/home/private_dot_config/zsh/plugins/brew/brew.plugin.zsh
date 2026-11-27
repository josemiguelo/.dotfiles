# still load brew since it can be used on several platforms
# `brew shellenv` is a bash script and costs ~25ms to fork; its output only
# changes when brew itself does, so serve it from a cache. On Omarchy brew
# reaches the shell only from here, never from /etc/profile.d, so the graphical
# session keeps the stock PATH (its dbus tools must win).
source $HOME/.local/lib/brew-prefix.sh
zcache brew $BREW_PREFIX/bin/brew shellenv
