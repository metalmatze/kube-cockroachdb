package main

import (
	"context"
	"flag"
	stdlog "log"
	"net/http"
	"os"
	"strings"

	"github.com/brancz/locutus/client"
	"github.com/brancz/locutus/config"
	"github.com/brancz/locutus/render/jsonnet"
	"github.com/brancz/locutus/rollout"
	"github.com/brancz/locutus/rollout/checks"
	"github.com/brancz/locutus/trigger/resource"
	"github.com/go-kit/kit/log"
	"github.com/go-kit/kit/log/level"
	"github.com/metalmatze/kube-cockroachdb/operator/actions"
	"github.com/metalmatze/signal/healthcheck"
	"github.com/metalmatze/signal/internalserver"
	"github.com/oklog/run"
	"github.com/prometheus/client_golang/prometheus"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {
	var (
		kubeconfigPath    string
		jsonnetPath       string
		renderConfigPath  string
		triggerConfigPath string
		loggerLevel       string
	)
	flag.StringVar(&kubeconfigPath, "kubeconfig", "", "Path to kubeconfig")
	flag.StringVar(&jsonnetPath, "jsonnet.main", "", "Path to the main jsonnet file to render")
	flag.StringVar(&renderConfigPath, "render.config", "", "Path to the render configuration")
	flag.StringVar(&triggerConfigPath, "trigger.config", "", "Path to the trigger configuration")
	flag.StringVar(&loggerLevel, "log.level", "info", "Change the verbosity of the logger (debug,info,warn,error)")
	flag.Parse()

	reg := prometheus.NewRegistry()
	healthchecks := healthcheck.NewMetricsHandler(healthcheck.NewHandler(), reg)

	logger := log.NewLogfmtLogger(log.NewSyncWriter(os.Stderr))
	logger = log.WithPrefix(logger, "ts", log.DefaultTimestampUTC)
	logger = log.WithPrefix(logger, "caller", log.DefaultCaller)

	switch strings.ToLower(loggerLevel) {
	case "debug":
		logger = level.NewFilter(logger, level.AllowDebug())
	case "info":
		logger = level.NewFilter(logger, level.AllowInfo())
	case "warn":
		logger = level.NewFilter(logger, level.AllowWarn())
	case "error":
		logger = level.NewFilter(logger, level.AllowError())
	}

	level.Info(logger).Log("msg", "initializing CockroachDB Operator")

	var gr run.Group
	{
		konfig, err := clientcmd.BuildConfigFromFlags("", kubeconfigPath)
		if err != nil {
			stdlog.Fatalf("error building kubeconfig: %v", err)
		}

		klient, err := kubernetes.NewForConfig(konfig)
		if err != nil {
			stdlog.Fatalf("error building kubernetes clientset: %v", err)
		}

		cl := client.NewClient(konfig, klient)
		cl.SetUpdatePreparations([]client.UpdatePreparation{
			client.UpdatePreparationFunc(client.PrepareServiceForUpdate),
			//client.UpdatePreparationFunc(client.PrepareStatefulsetForUpdate),
		})

		renderer := jsonnet.NewRenderer(logger, jsonnetPath)

		c := checks.NewSuccessChecks(logger, cl)

		runner := rollout.NewRunner(reg, log.With(logger, "component", "rollout-runner"), cl, renderer, c, false)
		runner.SetObjectActions([]rollout.ObjectAction{
			&rollout.CreateOrUpdateObjectAction{},
			&rollout.CreateIfNotExistObjectAction{},
			&actions.InitializeCockroachDBAction{Konfig: konfig, Klient: klient, Logger: logger},
			&actions.DecommissionNodeAction{Konfig: konfig, Klient: klient, Logger: logger},
			&actions.RecommissionNodeAction{Konfig: konfig, Klient: klient, Logger: logger},
		})

		trigger, err := resource.NewTrigger(logger, cl, triggerConfigPath)
		if err != nil {
			stdlog.Fatalf("error creating resource trigger: %v", err)
		}
		trigger.Register(config.NewConfigPasser(renderConfigPath, runner))

		ctx, shutdown := context.WithCancel(context.Background())
		gr.Add(func() error {
			level.Info(logger).Log("msg", "running CockroachDB Operator")
			return trigger.Run(ctx)
		}, func(err error) {
			shutdown()
		})
	}
	{
		h := internalserver.NewHandler(
			internalserver.WithName("CockroachDB Operator"),
			internalserver.WithPrometheusRegistry(reg),
			internalserver.WithHealthchecks(healthchecks),
			internalserver.WithPProf(),
		)

		s := http.Server{Addr: ":8081", Handler: h}

		gr.Add(func() error {
			level.Info(logger).Log("msg", "running internal server", "addr", s.Addr)
			return s.ListenAndServe()
		}, func(err error) {
			_ = s.Shutdown(context.Background())
		})
	}

	if err := gr.Run(); err != nil {
		stdlog.Fatalf("failed to run controller: %v", err)
	}
}
