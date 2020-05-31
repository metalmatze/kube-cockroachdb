local objects = {
  metadata:: {
    name: 'kube-cockroachdb',
    namespace: 'kube-cockroachdb',
    labels: {
      'app.kubernetes.io/name': 'kube-cockroachdb',
      'app.kubernetes.io/component': 'operator',
    },
  },

  deployment: {
    kind: 'Deployment',
    apiVersion: 'apps/v1',
    metadata: $.metadata,
    spec: {
      selector: {
        matchLabels: $.deployment.metadata.labels,
      },
      template: {
        metadata: {
          labels: $.deployment.metadata.labels,
        },
        spec: {
          serviceAccountName: $.serviceAccount.metadata.name,
          containers: [
            {
              name: 'kube-cockroachdb',
              image: 'quay.io/metalmatze/kube-cockroachdb',
              imagePullPolicy: 'Always',
              args: [
                '--jsonnet.main=main.jsonnet',
                '--trigger.config=config.yaml',
              ],
            },
          ],
        },
      },
    },
  },
  serviceAccount: {
    apiVersion: 'v1',
    kind: 'ServiceAccount',
    metadata: $.metadata,
  },
  clusterRole: {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRole',
    metadata: $.metadata,
    rules: [
      { apiGroups: ['metalmatze.de'], resources: ['cockroachdbs'], verbs: ['list', 'watch', 'patch'] },
      { apiGroups: ['metalmatze.de'], resources: ['cockroachdbs/status'], verbs: ['update'] },
      { apiGroups: [''], resources: ['services'], verbs: ['list', 'watch'] },
      { apiGroups: ['apps'], resources: ['statefulsets'], verbs: ['list', 'watch', 'get', 'create', 'update'] },
      { apiGroups: ['policy'], resources: ['poddisruptionbudgets'], verbs: ['list', 'watch'] },
      { apiGroups: ['monitoring.coreos.com'], resources: ['servicemonitors'], verbs: ['list', 'watch'] },
    ],
  },
  clusterRoleBinding: {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRoleBinding',
    metadata: $.metadata,
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: $.clusterRole.metadata.name,
    },
    subjects: [
      {
        kind: 'ServiceAccount',
        name: $.serviceAccount.metadata.name,
        namespace: $.serviceAccount.metadata.namespace,
      },
    ],
  },
  // podMonitor: {}
};

{
  apiVersion: 'v1',
  kind: 'List',
  items:
    [objects[name] for name in std.objectFields(objects)],
}
