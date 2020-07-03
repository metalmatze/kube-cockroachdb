# Auto generated binary variables helper managed by https://github.com/bwplotka/bingo v0.2.2. DO NOT EDIT.
# All tools are designed to be build inside $GOBIN.
GOPATH ?= $(shell go env GOPATH)
GOBIN  ?= $(firstword $(subst :, ,${GOPATH}))/bin
GO     ?= $(shell which go)

# Bellow generated variables ensure that every time a tool under each variable is invoked, the correct version
# will be used; reinstalling only if needed.
# For example for controller-gen variable:
#
# In your main Makefile (for non array binaries):
#
#include .bingo/Variables.mk # Assuming -dir was set to .bingo .
#
#command: $(CONTROLLER_GEN)
#	@echo "Running controller-gen"
#	@$(CONTROLLER_GEN) <flags/args..>
#
CONTROLLER_GEN := $(GOBIN)/controller-gen-v0.3.0
$(CONTROLLER_GEN): .bingo/controller-gen.mod
	@# Install binary/ries using Go 1.14+ build command. This is using bwplotka/bingo-controlled, separate go module with pinned dependencies.
	@echo "(re)installing $(GOBIN)/controller-gen-v0.3.0"
	@cd .bingo && $(GO) build -modfile=controller-gen.mod -o=$(GOBIN)/controller-gen-v0.3.0 "sigs.k8s.io/controller-tools/cmd/controller-gen"

EMBEDMD := $(GOBIN)/embedmd-v1.0.0
$(EMBEDMD): .bingo/embedmd.mod
	@# Install binary/ries using Go 1.14+ build command. This is using bwplotka/bingo-controlled, separate go module with pinned dependencies.
	@echo "(re)installing $(GOBIN)/embedmd-v1.0.0"
	@cd .bingo && $(GO) build -modfile=embedmd.mod -o=$(GOBIN)/embedmd-v1.0.0 "github.com/campoy/embedmd"

GOJSONTOYAML := $(GOBIN)/gojsontoyaml-v0.0.0-20200602132005-3697ded27e8c
$(GOJSONTOYAML): .bingo/gojsontoyaml.mod
	@# Install binary/ries using Go 1.14+ build command. This is using bwplotka/bingo-controlled, separate go module with pinned dependencies.
	@echo "(re)installing $(GOBIN)/gojsontoyaml-v0.0.0-20200602132005-3697ded27e8c"
	@cd .bingo && $(GO) build -modfile=gojsontoyaml.mod -o=$(GOBIN)/gojsontoyaml-v0.0.0-20200602132005-3697ded27e8c "github.com/brancz/gojsontoyaml"

JSONNET := $(GOBIN)/jsonnet-v0.16.0
$(JSONNET): .bingo/jsonnet.mod
	@# Install binary/ries using Go 1.14+ build command. This is using bwplotka/bingo-controlled, separate go module with pinned dependencies.
	@echo "(re)installing $(GOBIN)/jsonnet-v0.16.0"
	@cd .bingo && $(GO) build -modfile=jsonnet.mod -o=$(GOBIN)/jsonnet-v0.16.0 "github.com/google/go-jsonnet/cmd/jsonnet"

JSONNETFMT := $(GOBIN)/jsonnetfmt-v0.16.0
$(JSONNETFMT): .bingo/jsonnetfmt.mod
	@# Install binary/ries using Go 1.14+ build command. This is using bwplotka/bingo-controlled, separate go module with pinned dependencies.
	@echo "(re)installing $(GOBIN)/jsonnetfmt-v0.16.0"
	@cd .bingo && $(GO) build -modfile=jsonnetfmt.mod -o=$(GOBIN)/jsonnetfmt-v0.16.0 "github.com/google/go-jsonnet/cmd/jsonnetfmt"

