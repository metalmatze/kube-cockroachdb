package actions

import (
	"context"
	"fmt"
	"sort"
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

type DecommissionNodeAction struct {
	Konfig *rest.Config
	Klient *kubernetes.Clientset
	Logger log.Logger
}

func (a *DecommissionNodeAction) Name() string {
	return "DecommissionNode"
}

func (a *DecommissionNodeAction) Execute(rc *client.ResourceClient, u *unstructured.Unstructured) error {
	obj, err := rc.Get(context.TODO(), u.GetName(), metav1.GetOptions{})
	if apierrors.IsNotFound(err) {
		// There's no statefulset yet (during rollout),
		// so we don't need to check for decommissioning any pods.
		return nil
	}
	if err != nil {
		return err
	}

	currReplicas, ok, err := unstructured.NestedInt64(obj.Object, "spec", "replicas")
	if !ok || err != nil {
		return fmt.Errorf("failed to get current replicas while decommissioning node: %w", err)
	}

	newReplicas, ok, err := unstructured.NestedFloat64(u.Object, "spec", "replicas")
	if !ok || err != nil {
		return fmt.Errorf("failed to get new replicas while decommissioning node: %w", err)
	}

	// replica count doesn't decrease, not need to decommission
	if int64(newReplicas) >= currReplicas {
		level.Debug(a.Logger).Log("msg", "no nodes to decommission")
		return nil
	}

	podName := fmt.Sprintf("%s-%d", obj.GetName(), 0)
	podNamespace := obj.GetNamespace()

	nodeStatuses, err := getStatus(a.Konfig, a.Klient, podNamespace, podName)
	if err != nil {
		return fmt.Errorf("failed to get node statuses for decommission: %w", err)
	}

	sort.Slice(nodeStatuses, func(i, j int) bool {
		return nodeStatuses[i].Address < nodeStatuses[j].Address
	})

	var decommissionIDs []int64
	for i := currReplicas - 1; i >= int64(newReplicas); i-- {
		decommissionIDs = append(decommissionIDs, nodeStatuses[i].ID)
	}

	if len(decommissionIDs) == 0 {
		fmt.Println("No nodes to decommission")
		return nil
	}

	command := []string{"cockroach", "node", "decommission", "--insecure"}
	for _, id := range decommissionIDs {
		command = append(command, fmt.Sprintf("%d", id))
	}
	level.Debug(a.Logger).Log("msg", "decommissioning nodes", "command", strings.Join(command, " "))
	start := time.Now()
	_, _, err = podExec(a.Konfig, a.Klient, podNamespace, podName, command)
	if err != nil {
		return err
	}

	level.Info(a.Logger).Log(
		"msg", "successfully decommissioned nodes",
		"command", strings.Join(command, " "),
		"duration", time.Since(start),
	)

	return nil
}
