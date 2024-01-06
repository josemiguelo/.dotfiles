export ASDF_GOLANG_MOD_VERSION_ENABLED=true

GOV=$(asdf where golang)

export GOROOT=$GOV/go
export GOPATH=$GOV/packages
export PATH=$PATH:$GOPATH/bin
export GOPRIVATE=
