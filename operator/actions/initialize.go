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
	"k8s.io/client-go/deprecated/scheme"
	"k8s.io/client-go/kubernetes"
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

func (a *InitializeCockroachDBAction) Execute(rc *client.ResourceClient, u *unstructured.Unstructured) error {
	obj, err := rc.Get(context.TODO(), u.GetName(), metav1.GetOptions{})
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
	pod, err := klient.CoreV1().Pods(namespace).Get(context.TODO(), name, metav1.GetOptions{})
	if err != nil {
		return nil, nil, err
	}

	req := klient.CoreV1().RESTClient().
		Post().
		Resource("pods").
		Name(pod.GetName()).
		Namespace(pod.GetNamespace()).
		SubResource("exec").
		Timeout(time.Second)
	req.VersionedParams(&v1.PodExecOptions{
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
	err = exec.Stream(remotecommand.StreamOptions{
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
	for _, line := range lines {
		columns := strings.Split(line, "\t")
		if len(columns) != 22 {
			return status, fmt.Errorf("parsing status failed as 22 columns expected but got: %d", len(columns))
		}
		if columns[0] == "id" {
			continue
		}

		id, err := strconv.ParseInt(columns[0], 10, 64)
		if err != nil {
			return status, err
		}

		status = append(status, NodeStatus{
			ID:              id,
			Address:         columns[1],
			Available:       parseBool(columns[7]),
			Live:            parseBool(columns[8]),
			Decommissioning: parseBool(columns[20]),
			Draining:        parseBool(columns[21]),
		})
	}

	return status, nil
}
