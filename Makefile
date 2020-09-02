all: test build examples README.md

build: operator/operator

.PHONY: test
test:
	CGO_ENABLED=0 go test -v ./operator/...

operator/operator: $(shell find ./operator -type f -name '*.go')
	CGO_ENABLED=0 go build -v -ldflags '-w -extldflags '-static'' -o operator ./operator/...

operator/metalmatze.de_cockroachdbs.yaml: $(shell find ./operator/api/v1alphav1 -type f -name '*.go') | .bingo/bin/controller-gen
	.bingo/bin/controller-gen crd paths="./operator/..." output:crd:artifacts:config=./operator

operator/api/v1alphav1/zz_generated.deepcopy.go: $(shell find ./operator/api/v1alphav1 -type f -name '*.go' -not -name '*.deepcopy.go') | .bingo/bin/controller-gen
	.bingo/bin/controller-gen object paths="./operator/..."

operator/deployment.yaml: operator/deployment.jsonnet
	.bingo/bin/jsonnetfmt -i operator/deployment.jsonnet
	.bingo/bin/jsonnet operator/deployment.jsonnet | .bingo/bin/gojsontoyaml > operator/deployment.yaml

examples: examples/basic/basic.yaml examples/storage/storage.yaml

examples/basic/basic.yaml: examples/basic/basic.jsonnet kubernetes.libsonnet | .bingo/bin/jsonnet .bingo/bin/jsonnetfmt .bingo/bin/gojsontoyaml
	.bingo/bin/jsonnetfmt -i kubernetes.libsonnet examples/basic/basic.jsonnet
	.bingo/bin/jsonnet examples/basic/basic.jsonnet | .bingo/bin/gojsontoyaml > examples/basic/basic.yaml

examples/storage/storage.yaml: examples/storage/storage.jsonnet kubernetes.libsonnet | .bingo/bin/jsonnet .bingo/bin/jsonnetfmt .bingo/bin/gojsontoyaml
	.bingo/bin/jsonnetfmt -i kubernetes.libsonnet examples/storage/storage.jsonnet
	.bingo/bin/jsonnet examples/storage/storage.jsonnet | .bingo/bin/gojsontoyaml > examples/storage/storage.yaml

README.md: $(shell find examples/ -name "*.jsonnet") | .bingo/bin/embedmd .bingo/bin/gh-md-toc
	.bingo/bin/embedmd -w README.md
	.bingo/bin/gh-md-toc --insert README.md > /dev/null
	-rm -rf README.md.{orig,toc}.*

PHONY: .tags
.tags:
	 echo "latest,$(shell git rev-parse --short HEAD)" > .tags

monitoring/examples/prometheus.yaml: $(shell find monitoring/ -type f -and -name "*.jsonnet" -or -name "*.libsonnet") | .bingo/bin/jsonnet .bingo/bin/gojsontoyaml
	.bingo/bin/jsonnet monitoring/examples.jsonnet | .bingo/bin/gojsontoyaml > monitoring/examples/prometheus.yaml

.bingo/bin/gh-md-toc:
	curl -Lo $@ https://raw.githubusercontent.com/ekalinin/github-markdown-toc/master/gh-md-toc
	chmod +x $@

.bingo/bin/controller-gen:
	go build -modfile .bingo/controller-gen.mod -o .bingo/bin/controller-gen sigs.k8s.io/controller-tools/cmd/controller-gen

.bingo/bin/embedmd:
	go build -modfile .bingo/embedmd.mod -o .bingo/bin/embedmd github.com/campoy/embedmd

.bingo/bin/gojsontoyaml:
	go build -modfile .bingo/gojsontoyaml.mod -o .bingo/bin/gojsontoyaml github.com/brancz/gojsontoyaml

.bingo/bin/jsonnet:
	go build -modfile .bingo/jsonnet.mod -o .bingo/bin/jsonnet github.com/google/go-jsonnet/cmd/jsonnet

.bingo/bin/jsonnetfmt:
	go build -modfile .bingo/jsonnetfmt.mod -o .bingo/bin/jsonnetfmt github.com/google/go-jsonnet/cmd/jsonnetfmt
