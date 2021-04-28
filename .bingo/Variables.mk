# Auto generated binary variables helper managed by https://github.com/bwplotka/bingo v0.4.0. DO NOT EDIT.
# All tools are designed to be build inside $GOBIN.
BINGO_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
GOPATH ?= $(shell go env GOPATH)
GOBIN  ?= $(firstword $(subst :, ,${GOPATH}))/bin
GO     ?= $(shell which go)

# Below generated variables ensure that every time a tool under each variable is invoked, the correct version
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
CONTROLLER_GEN := $(GOBIN)/controller-gen-v0.5.0
$(CONTROLLER_GEN): $(BINGO_DIR)/controller-gen.mod
	@# Install binary/ries using Go 1.14+ build command. This is using bwplotka/bingo-controlled, separate go module with pinned dependencies.
	@echo "(re)installing $(GOBIN)/controller-gen-v0.5.0"
	@cd $(BINGO_DIR) && $(GO) build -mod=mod -modfile=controller-gen.mod -o=$(GOBIN)/controller-gen-v0.5.0 "sigs.k8s.io/controller-tools/cmd/controller-gen"

EMBEDMD := $(GOBIN)/embedmd-v1.0.0
$(EMBEDMD): $(BINGO_DIR)/embedmd.mod
	@# Install binary/ries using Go 1.14+ build command. This is using bwplotka/bingo-controlled, separate go module with pinned dependencies.
	@echo "(re)installing $(GOBIN)/embedmd-v1.0.0"
	@cd $(BINGO_DIR) && $(GO) build -mod=mod -modfile=embedmd.mod -o=$(GOBIN)/embedmd-v1.0.0 "github.com/campoy/embedmd"

GOJSONTOYAML := $(GOBIN)/gojsontoyaml-v0.0.0-20201216083616-202f76bf8c1f
$(GOJSONTOYAML): $(BINGO_DIR)/gojsontoyaml.mod
	@# Install binary/ries using Go 1.14+ build command. This is using bwplotka/bingo-controlled, separate go module with pinned dependencies.
	@echo "(re)installing $(GOBIN)/gojsontoyaml-v0.0.0-20201216083616-202f76bf8c1f"
	@cd $(BINGO_DIR) && $(GO) build -mod=mod -modfile=gojsontoyaml.mod -o=$(GOBIN)/gojsontoyaml-v0.0.0-20201216083616-202f76bf8c1f "github.com/brancz/gojsontoyaml"

JSONNET := $(GOBIN)/jsonnet-v0.17.0
$(JSONNET): $(BINGO_DIR)/jsonnet.mod
	@# Install binary/ries using Go 1.14+ build command. This is using bwplotka/bingo-controlled, separate go module with pinned dependencies.
	@echo "(re)installing $(GOBIN)/jsonnet-v0.17.0"
	@cd $(BINGO_DIR) && $(GO) build -mod=mod -modfile=jsonnet.mod -o=$(GOBIN)/jsonnet-v0.17.0 "github.com/google/go-jsonnet/cmd/jsonnet"

JSONNETFMT := $(GOBIN)/jsonnetfmt-v0.17.0
$(JSONNETFMT): $(BINGO_DIR)/jsonnetfmt.mod
	@# Install binary/ries using Go 1.14+ build command. This is using bwplotka/bingo-controlled, separate go module with pinned dependencies.
	@echo "(re)installing $(GOBIN)/jsonnetfmt-v0.17.0"
	@cd $(BINGO_DIR) && $(GO) build -mod=mod -modfile=jsonnetfmt.mod -o=$(GOBIN)/jsonnetfmt-v0.17.0 "github.com/google/go-jsonnet/cmd/jsonnetfmt"

