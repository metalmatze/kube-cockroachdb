FROM alpine:3.11

COPY ./operator /kube-cockroachdb/operator/operator
COPY ./config.yaml /kube-cockroachdb/operator/config.yaml
COPY ./main.jsonnet /kube-cockroachdb/operator/main.jsonnet
COPY ./kubernetes.libsonnet /kube-cockroachdb/operator/kubernetes.libsonnet

COPY ./monitoring/alerts/cockroachdb.libsonnet /kube-cockroachdb/monitoring/alerts/cockroachdb.libsonnet
COPY ./monitoring/config.libsonnet /kube-cockroachdb/monitoring/config.libsonnet
COPY ./monitoring/mixin.libsonnet /kube-cockroachdb/monitoring/mixin.libsonnet
COPY ./monitoring/rules/cockroachdb.libsonnet /kube-cockroachdb/monitoring/rules/cockroachdb.libsonnet

WORKDIR /kube-cockroachdb/operator
ENTRYPOINT [ "/kube-cockroachdb/operator/operator" ]
