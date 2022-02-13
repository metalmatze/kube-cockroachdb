FROM golang:1.17-alpine AS build

ARG ARCH=amd64
ENV CGO_ENABLED=0
ENV GOOS=linux
ENV GOARCH=$ARCH

RUN mkdir /app && apk add --no-cache make
WORKDIR /app
COPY . /app

RUN make build -o operator/api/v1alphav1/zz_generated.deepcopy.go
RUN cp ./kubernetes.libsonnet ./operator/kubernetes.libsonnet

FROM alpine:3.11

COPY --from=build /app/operator/operator /kube-cockroachdb/operator/operator
COPY --from=build /app/operator/config.yaml /kube-cockroachdb/operator/config.yaml
COPY --from=build /app/operator/main.jsonnet /kube-cockroachdb/operator/main.jsonnet
COPY --from=build /app/operator/kubernetes.libsonnet /kube-cockroachdb/operator/kubernetes.libsonnet

WORKDIR /kube-cockroachdb/operator
ENTRYPOINT [ "/kube-cockroachdb/operator/operator" ]
