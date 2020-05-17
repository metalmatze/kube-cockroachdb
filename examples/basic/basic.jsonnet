local kubernetes = import '../../kubernetes.libsonnet';

local basic = kubernetes({
  name: 'basic',
  replicas: 3,
});

// Let's generate a List containing all Kubernetes objects
{
  apiVersion: 'v1',
  kind: 'List',
  items:
    [basic[name] for name in std.objectFields(basic)],
}
