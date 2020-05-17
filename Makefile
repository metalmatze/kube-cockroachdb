examples: examples/basic/basic.yaml examples/simple/simple.yaml

examples/basic/basic.yaml: examples/basic/basic.jsonnet kubernetes.libsonnet
	jsonnetfmt -i kubernetes.libsonnet examples/basic/basic.jsonnet
	jsonnet examples/basic/basic.jsonnet | gojsontoyaml > examples/basic/basic.yaml

examples/simple/simple.yaml: examples/simple/simple.jsonnet kubernetes.libsonnet
	jsonnetfmt -i kubernetes.libsonnet examples/simple/simple.jsonnet
	jsonnet examples/simple/simple.jsonnet | gojsontoyaml > examples/simple/simple.yaml
