local kubernetes = import '../../kubernetes.libsonnet';

local objects = kubernetes({
  name: 'example',
  replicas: 3,

  storage: {
    // emptyDir: {},
    volumeClaimTemplate: {
      apiVersion: 'v1',
      kind: 'PersistentVolumeClaim',
      spec: {
        accessModes: [
          'ReadWriteOnce',
        ],
        resources: {
          requests: {
            storage: '25Gi',
          },
        },
        storageClassName: 'standard',
      },
    },
  },
});

// Let's generate a List containing all Kubernetes objects
{
  apiVersion: 'v1',
  kind: 'List',
  items:
    [objects[name] for name in std.objectFields(objects)],
}
