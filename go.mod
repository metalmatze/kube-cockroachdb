module github.com/metalmatze/kube-cockroachdb

go 1.14

require (
	github.com/brancz/locutus v0.0.0-20200430073700-65b7640ed9bc
	github.com/go-kit/kit v0.10.0
	github.com/metalmatze/signal v0.0.0-20200428133549-c4243ecaf121
	github.com/oklog/run v1.1.0
	github.com/prometheus/client_golang v1.5.1
	k8s.io/api v0.18.2
	k8s.io/apimachinery v0.18.2
	k8s.io/client-go v0.18.2
	sigs.k8s.io/controller-runtime v0.6.0
)

replace github.com/brancz/locutus => github.com/metalmatze/locutus v0.0.0-20200526233827-d87182291dbf
