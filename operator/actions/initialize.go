package actions

import (
	"bytes"
	"context"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/brancz/locutus/client"
	"github.com/go-kit/kit/log"
	"github.com/go-kit/kit/log/level"
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/kubernetes/scheme"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/remotecommand"
)

type InitializeCockroachDBAction struct {
	Konfig *rest.Config
	Klient *kubernetes.Clientset
	Logger log.Logger
}

func (a *InitializeCockroachDBAction) Name() string {
	return "InitializeIfNot"
}

func (a *InitializeCockroachDBAction) Execute(ctx context.Context, rc *client.ResourceClient, u *unstructured.Unstructured) error {
	obj, err := rc.Get(ctx, u.GetName(), metav1.GetOptions{})
	if err != nil {
		return fmt.Errorf("failed to get resource while initializing CockroachDB")
	}

	// Get number of replicas in StatefulSet
	replicas, ok, err := unstructured.NestedInt64(obj.Object, "spec", "replicas")
	if !ok || err != nil {
		return fmt.Errorf("failed to get replicas while initializing CockroachDB: %w", err)
	}

	if replicas < 1 {
		return nil
	}

	podNamespace := obj.GetNamespace()
	podName := fmt.Sprintf("%s-%d", obj.GetName(), 0)

	command := []string{"cockroach", "init", "--insecure", fmt.Sprintf("--host=%s.%s.%s", podName, obj.GetName(), podNamespace)}
	level.Debug(a.Logger).Log("msg", "initializing CockroachDB cluster", "command", strings.Join(command, " "))
	start := time.Now()
	_, stderr, err := podExec(a.Konfig, a.Klient, podNamespace, podName, command)
	if stderr != nil {
		if strings.Contains(stderr.String(), "cluster has already been initialized") {
			return nil
		}
	}
	if err != nil {
		fmt.Println(err, stderr.String())
		// TODO: Should be made a transient error
		return nil
	}

	level.Info(a.Logger).Log(
		"msg", "successfully initialized CockroachDB cluster",
		"command", strings.Join(command, " "),
		"duration", time.Since(start),
	)

	return nil
}

func podExec(konfig *rest.Config, klient *kubernetes.Clientset, namespace string, name string, command []string) (*bytes.Buffer, *bytes.Buffer, error) {
	ctx := context.TODO()
	pod, err := klient.CoreV1().Pods(namespace).Get(ctx, name, metav1.GetOptions{})
	if err != nil {
		return nil, nil, err
	}

	req := klient.CoreV1().RESTClient().
		Post().
		Resource("pods").
		Name(pod.GetName()).
		Namespace(pod.GetNamespace()).
		SubResource("exec").
		Timeout(10*time.Second).
		VersionedParams(&v1.PodExecOptions{
			Container: pod.Spec.Containers[0].Name,
			Command:   command,
			Stdout:    true,
			Stderr:    true,
		}, scheme.ParameterCodec)

	exec, err := remotecommand.NewSPDYExecutor(konfig, "POST", req.URL())
	if err != nil {
		return nil, nil, fmt.Errorf("failed to create executor: %w", err)
	}

	stdout := &bytes.Buffer{}
	stderr := &bytes.Buffer{}
	err = exec.StreamWithContext(ctx, remotecommand.StreamOptions{
		Stdout: stdout,
		Stderr: stderr,
		Tty:    false,
	})

	if err != nil {
		return stdout, stderr, fmt.Errorf("failed to execute: %w", err)
	}

	return stdout, stderr, nil
}

type NodeStatus struct {
	ID              int64
	Address         string
	Available       bool
	Live            bool
	Decommissioning bool
	Draining        bool
}

func getStatus(konfig *rest.Config, klient *kubernetes.Clientset, namespace string, name string) ([]NodeStatus, error) {
	command := []string{"cockroach", "node", "status", "--insecure", "--all", "--format=tsv"}
	stdout, _, err := podExec(konfig, klient, namespace, name, command)
	if err != nil {
		return nil, err
	}
	return parseStatus(stdout.String())
}

func parseStatus(stdout string) ([]NodeStatus, error) {
	var status []NodeStatus

	parseBool := func(in string) bool {
		if in == "true" {
			return true
		}
		return false
	}

	stdout = strings.TrimSpace(stdout)
	lines := strings.Split(stdout, "\n")

	idColumnIndex := -1
	addressColumnIndex := -1
	isAvailableColumnIndex := -1
	isLiveColumnIndex := -1
	isDecommissioningColumnIndex := -1
	isDrainingColumnIndex := -1

	headerLine := lines[0]
	columns := strings.Split(headerLine, "\t")
	for i, column := range columns {
		switch column {
		case "id":
			idColumnIndex = i
		case "address":
			addressColumnIndex = i
		case "is_available":
			isAvailableColumnIndex = i
		case "is_live":
			isLiveColumnIndex = i
		case "is_decommissioning":
			isDecommissioningColumnIndex = i
		case "is_draining":
			isDrainingColumnIndex = i
		}
	}

	if idColumnIndex == -1 {
		return nil, fmt.Errorf("failed to find id column in status output")
	}

	if addressColumnIndex == -1 {
		return nil, fmt.Errorf("failed to find address column in status output")
	}

	if isAvailableColumnIndex == -1 {
		return nil, fmt.Errorf("failed to find is_available column in status output")
	}

	if isLiveColumnIndex == -1 {
		return nil, fmt.Errorf("failed to find is_live column in status output")
	}

	if isDecommissioningColumnIndex == -1 {
		return nil, fmt.Errorf("failed to find is_decommissioning column in status output")
	}

	if isDrainingColumnIndex == -1 {
		return nil, fmt.Errorf("failed to find is_draining column in status output")
	}

	// Exclude the header line.
	for _, line := range lines[1:] {
		columns := strings.Split(line, "\t")
		id, err := strconv.ParseInt(columns[idColumnIndex], 10, 64)
		if err != nil {
			return status, err
		}

		status = append(status, NodeStatus{
			ID:              id,
			Address:         columns[addressColumnIndex],
			Available:       parseBool(columns[isAvailableColumnIndex]),
			Live:            parseBool(columns[isLiveColumnIndex]),
			Decommissioning: parseBool(columns[isDecommissioningColumnIndex]),
			Draining:        parseBool(columns[isDrainingColumnIndex]),
		})
	}

	return status, nil
}
