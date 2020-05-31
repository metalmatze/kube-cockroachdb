FROM alpine:3.11

COPY ./operator /kube-cockroachdb/operator/operator
COPY ./config.yaml /kube-cockroachdb/operator/config.yaml
COPY ./main.jsonnet /kube-cockroachdb/operator/main.jsonnet
COPY ./kubernetes.libsonnet /kube-cockroachdb/operator/kubernetes.libsonnet

WORKDIR /kube-cockroachdb/operator
ENTRYPOINT [ "/kube-cockroachdb/operator/operator" ]
