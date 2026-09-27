# try, set up the way Omarchy does for bash (default/bash/init): `try init`
# defines the try function that can cd this shell into ~/Work/tries/…, loaded
# the first time try runs so every shell doesn't start ruby.
if (( $+commands[try] )); then
  try() {
    unfunction try
    eval "$(SHELL=${commands[zsh]:-zsh} command try init ~/Work/tries)"
    try "$@"
  }
fi
