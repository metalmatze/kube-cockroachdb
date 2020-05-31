build: operator/operator

.PHONY: test
test:
	CGO_ENABLED=0 go test -v ./operator/...

operator/operator: $(shell find ./operator -type f -name '*.go')
	CGO_ENABLED=0 go build -v -ldflags '-w -extldflags '-static'' -o operator ./operator/...

operator/metalmatze.de_cockroachdbs.yaml: tmp/bin/controller-gen $(shell find ./operator/api/v1alphav1 -type f -name '*.go')
	./tmp/bin/controller-gen crd paths="./operator/..." output:crd:artifacts:config=./operator

operator/api/v1alphav1/zz_generated.deepcopy.go: tmp/bin/controller-gen $(shell find ./operator/api/v1alphav1 -type f -name '*.go' -not -name '*.deepcopy.go')
	./tmp/bin/controller-gen object paths="./operator/..."

operator/deployment.yaml: operator/deployment.jsonnet
	jsonnetfmt -i operator/deployment.jsonnet
	jsonnet operator/deployment.jsonnet | gojsontoyaml > operator/deployment.yaml

tmp/bin/controller-gen:
	CGO_ENABLED=0 GO111MODULE="on" go build -o $@ sigs.k8s.io/controller-tools/cmd/controller-gen

examples: examples/basic/basic.yaml examples/pvc/pvc.yaml

examples/basic/basic.yaml: examples/basic/basic.jsonnet kubernetes.libsonnet
	jsonnetfmt -i kubernetes.libsonnet examples/basic/basic.jsonnet
	jsonnet examples/basic/basic.jsonnet | gojsontoyaml > examples/basic/basic.yaml

examples/pvc/pvc.yaml: examples/pvc/pvc.jsonnet kubernetes.libsonnet
	jsonnetfmt -i kubernetes.libsonnet examples/pvc/pvc.jsonnet
	jsonnet examples/pvc/pvc.jsonnet | gojsontoyaml > examples/pvc/pvc.yaml

README.md: tmp/bin/embedmd tmp/bin/gh-md-toc $(shell find examples/ -name "*.jsonnet")
	tmp/bin/embedmd -w README.md
	tmp/bin/gh-md-toc --insert README.md > /dev/null
	-rm -rf README.md.{orig,toc}.*

tmp/bin/embedmd:
	GO111MODULE="on" go build -o $@ github.com/campoy/embedmd

tmp/bin/gh-md-toc:
	mkdir -p tmp/bin/
	curl -Lo $@ https://raw.githubusercontent.com/ekalinin/github-markdown-toc/master/gh-md-toc
	chmod +x $@

PHONY: .tags
.tags:
	 echo "latest,$(shell git rev-parse --short HEAD)" > .tags
