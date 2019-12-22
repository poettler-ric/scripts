#!/usr/bin/env sh

# emacs doom go support
go get -u github.com/motemen/gore/cmd/gore
go get -u golang.org/x/tools/cmd/godoc
go get -u golang.org/x/tools/cmd/goimports
go get -u golang.org/x/tools/cmd/gorename
go get -u golang.org/x/tools/cmd/guru
go get -u golang.org/x/tools/cmd/gopls
go get -u github.com/cweill/gotests/...
go get -u github.com/fatih/gomodifytags
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b "$(go env GOPATH)/bin v1.21.0"
# deprecated (doom doctor will cry)
# go get -u golang.org/x/tools/cmd/godoc

# hugo
# go get -u github.com/gohugoio/hugo
