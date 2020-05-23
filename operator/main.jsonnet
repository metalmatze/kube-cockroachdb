local kubernetes = import '../kubernetes.libsonnet';
local config = import 'generic-operator/config';

{
  objects: std.mapWithKey(
    // inject owner references into all Kubernetes objects
    function(k, v) v {
      metadata+: {
        ownerReferences: [{
          apiVersion: config.apiVersion,
          blockOwnerdeletion: true,
          controller: true,
          kind: config.kind,
          name: config.metadata.name,
          uid: config.metadata.uid,
        }],
      },
    },
    // Generate kubernetes objects in kubernetes function for give params
    kubernetes({
      name: config.metadata.name,
      metadata+: {
        namespace: config.metadata.namespace,
      },
      replicas: config.spec.replicas,
      resources: if std.objectHas(config.spec, 'resources') then config.spec.resources else {},
      pvc: {
        size: '1Gi',
        class: 'standard',
      },
    })
  ),
  rollout: {
    apiVersion: 'workflow.kubernetes.io/v1alpha1',
    kind: 'Rollout',
    metadata: {
      name: 'jsonnet',
    },
    spec: {
      groups: [
        {
          name: 'Rollout CockroachDB',
          steps: [
            {
              action: 'DecommissionNode',
              object: 'statefulSet',
            },
            {
              action: 'CreateOrUpdate',
              object: 'statefulSet',
              success: [
                {
                  fieldComparisons: [
                    {
                      name: 'Generation correct',
                      path: '{.metadata.generation}',
                      value: {
                        path: '{.status.observedGeneration}',
                      },
                    },
                    {
                      name: 'All replicas updated',
                      path: '{.status.replicas}',
                      value: {
                        path: '{.status.updatedReplicas}',
                      },
                    },
                    {
                      name: 'No replica unavailable',
                      path: '{.status.unavailableReplicas}',
                      default: 0,
                      value: {
                        static: 0,
                      },
                    },
                  ],
                },
              ],
            },
            {
              action: 'CreateOrUpdate',
              object: 'service',
            },
            {
              action: 'CreateOrUpdate',
              object: 'servicePublic',
            },
            {
              action: 'CreateOrUpdate',
              object: 'serviceMonitor',
            },
            {
              action: 'InitializeIfNot',
              object: 'statefulSet',
            },
            {
              action: 'RecommissionNode',
              object: 'statefulSet',
            },
          ],
        },
      ],
    },
  },
}
