local kubernetes = import '../../kubernetes.libsonnet';

local objects = kubernetes({
  name: 'example',
  replicas: 3,

  pvc: {
    size: '5Gi',
    class: 'standard',
  },
});

// Let's generate a List containing all Kubernetes objects
{
  apiVersion: 'v1',
  kind: 'List',
  items:
    [objects[name] for name in std.objectFields(objects)],
}
