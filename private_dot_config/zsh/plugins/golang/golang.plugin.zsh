export ASDF_GOLANG_MOD_VERSION_ENABLED=true

if (( ${+commands[go]} )); then
  GOV=$(asdf where golang 2>/dev/null)
  export GOROOT="$GOV/go"
  export GOPATH="$GOV/packages"
  export PATH="$PATH:$GOPATH/bin"
  export GOPRIVATE=""
fi
