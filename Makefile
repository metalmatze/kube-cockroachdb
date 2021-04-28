include .bingo/Variables.mk

all: test build examples README.md

build: operator/operator

.PHONY: test
test:
	CGO_ENABLED=0 go test -v ./operator/...

operator/operator: $(shell find ./operator -type f -name '*.go')
	CGO_ENABLED=0 go build -v -ldflags '-w -extldflags '-static'' -o operator ./operator/...

operator/metalmatze.de_cockroachdbs.yaml: $(shell find ./operator/api/v1alphav1 -type f -name '*.go') | $(CONTROLLER_GEN)
	$(CONTROLLER_GEN) crd paths="./operator/..." output:crd:artifacts:config=./operator

operator/api/v1alphav1/zz_generated.deepcopy.go: $(shell find ./operator/api/v1alphav1 -type f -name '*.go' -not -name '*.deepcopy.go') | operator/metalmatze.de_cockroachdbs.yaml
	operator/metalmatze.de_cockroachdbs.yaml object paths="./operator/..."

operator/deployment.yaml: operator/deployment.jsonnet
	$(JSONNETFMT) -i operator/deployment.jsonnet
	$(JSONNET) operator/deployment.jsonnet | $(GOJSONTOYAML) > operator/deployment.yaml

examples: examples/basic/basic.yaml examples/storage/storage.yaml

examples/basic/basic.yaml: examples/basic/basic.jsonnet kubernetes.libsonnet | $(JSONNET) $(JSONNETFMT) $(GOJSONTOYAML)
	$(JSONNETFMT) -i kubernetes.libsonnet examples/basic/basic.jsonnet
	$(JSONNET) examples/basic/basic.jsonnet | $(GOJSONTOYAML) > examples/basic/basic.yaml

examples/storage/storage.yaml: examples/storage/storage.jsonnet kubernetes.libsonnet | $(JSONNET) $(JSONNETFMT) $(GOJSONTOYAML)
	$(JSONNETFMT) -i kubernetes.libsonnet examples/storage/storage.jsonnet
	$(JSONNET) examples/storage/storage.jsonnet | $(GOJSONTOYAML) > examples/storage/storage.yaml

README.md: $(shell find examples/ -name "*.jsonnet") | $(EMBEDMD) .bingo/bin/gh-md-toc
	$(EMBEDMD) -w README.md
	.bingo/bin/gh-md-toc --insert README.md > /dev/null
	-rm -rf README.md.{orig,toc}.*

PHONY: .tags
.tags:
	 echo "latest,$(shell git rev-parse --short HEAD)" > .tags

monitoring/examples/prometheus.yaml: $(shell find monitoring/ -type f -and -name "*.jsonnet" -or -name "*.libsonnet") | $(JSONNET) $(GOJSONTOYAML)
	$(JSONNET) monitoring/examples.jsonnet | $(GOJSONTOYAML) > monitoring/examples/prometheus.yaml

.bingo/bin/gh-md-toc:
	curl -Lo $@ https://raw.githubusercontent.com/ekalinin/github-markdown-toc/master/gh-md-toc
	chmod +x $@
