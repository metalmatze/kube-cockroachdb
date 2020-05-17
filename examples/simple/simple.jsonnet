local kubernetes = import '../../kubernetes.libsonnet';

local simple = kubernetes({ name: 'simple' });

// Let's generate a List containing all Kubernetes objects
{
  apiVersion: 'v1',
  kind: 'List',
  items:
    [simple[name] for name in std.objectFields(simple)],
}
