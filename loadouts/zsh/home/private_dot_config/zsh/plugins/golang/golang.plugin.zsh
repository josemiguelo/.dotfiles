# GOPATH stays per go version, next to its install (packages/), with its bin
# on PATH, and follows the go in use: mise exports GOROOT for it
# (go.set_goroot) at startup and again from its precmd and chpwd hooks when
# the version changes (a cd into a project that pins another go). This plugin
# loads after mise's, so its hooks run after mise's: GOPATH is GOROOT's,
# read without starting a process, and the previous go's bin leaves PATH.
# mise's hook rewrites PATH (dropping GOPATH/bin), so every run puts it back.
_golang_gopath() {
  [[ -n $GOROOT ]] || return 0
  local gopath=$GOROOT/packages
  if [[ $GOPATH != $gopath ]]; then
    [[ -n $GOPATH ]] && path=(${path:#$GOPATH/bin})
    export GOPATH=$gopath
  fi
  (( ${path[(Ie)$GOPATH/bin]} )) || path+=($GOPATH/bin)
}
export GOPRIVATE=""
_golang_gopath
autoload -Uz add-zsh-hook
add-zsh-hook precmd _golang_gopath
add-zsh-hook chpwd _golang_gopath
