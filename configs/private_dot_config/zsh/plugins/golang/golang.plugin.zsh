# mise exports GOROOT for the go in use (go.set_goroot); GOPATH stays per go
# version, next to its install, with its bin on PATH.
if (( ${+commands[go]} )); then
  GOV=$(mise where go 2>/dev/null)
  export GOPATH="$GOV/packages"
  export PATH="$PATH:$GOPATH/bin"
  export GOPRIVATE=""
fi
