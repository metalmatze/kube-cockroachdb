package actions

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/brancz/locutus/client"
	"github.com/go-kit/kit/log"
	"github.com/go-kit/kit/log/level"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

type RecommissionNodeAction struct {
	Konfig *rest.Config
	Klient *kubernetes.Clientset
	Logger log.Logger
}

func (a *RecommissionNodeAction) Name() string {
	return "RecommissionNode"
}

func (a *RecommissionNodeAction) Execute(rc *client.ResourceClient, u *unstructured.Unstructured) error {
	obj, err := rc.Get(context.TODO(), u.GetName(), metav1.GetOptions{})
	if apierrors.IsNotFound(err) {
		// There's no statefulset yet (during rollout),
		// so we don't need to check for decommissioning any pods.
		return nil
	}
	if err != nil {
		return err
	}

	podName := fmt.Sprintf("%s-%d", obj.GetName(), 0)
	podNamespace := obj.GetNamespace()

	nodeStatuses, err := getStatus(a.Konfig, a.Klient, podNamespace, podName)
	if err != nil {
		return fmt.Errorf("failed to get node statuses for recommission: %w", err)
	}

	var recommissionIDs []int64
	for _, ns := range nodeStatuses {
		if ns.Live && ns.Available && !ns.Draining && ns.Decommissioning {
			recommissionIDs = append(recommissionIDs, ns.ID)
		}
	}

	if len(recommissionIDs) == 0 {
		level.Debug(a.Logger).Log("msg", "no nodes to recommission")
		return nil
	}

	start := time.Now()

	command := []string{"cockroach", "node", "recommission", "--insecure", "--self"}
	level.Debug(a.Logger).Log("msg", "recommissioning nodes", "command", strings.Join(command, " "))
	for _, id := range recommissionIDs {
		command = append(command, fmt.Sprintf("%d", id))
	}
	_, _, err = podExec(a.Konfig, a.Klient, podNamespace, podName, command)
	if err != nil {
		return err
	}

	level.Info(a.Logger).Log(
		"msg", "successfully recommissioned nodes",
		"command", strings.Join(command, " "),
		"duration", time.Since(start),
	)

	return nil
}
