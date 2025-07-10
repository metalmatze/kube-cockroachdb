function(params) {
  local cockroachdb =
    {
      local defaults = self,
      name: 'cockroachdb',

      metadata: {
        name: 'cockroachdb-' + defaults.name,
        namespace: 'default',
        labels: {
          'app.kubernetes.io/name': 'cockroachdb-' + defaults.name,
          'app.kubernetes.io/instance': defaults.name,
          'app.kubernetes.io/component': 'database',
        },
      },
      image: 'cockroachdb/cockroach:v20.1.5',
      replicas: 1,
      expose: {
        http: 8080,
        grpc: 26257,
      },
      resources: {},
      storage: {},
      extraArgs: [],
    }
    + params,  // this merges your parameters with default ones

  // We now generate all Kubernetes objects based on the cockroach configuration created above

  servicePublic: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: cockroachdb.metadata {
      name: cockroachdb.metadata.name + '-public',
      labels+: {
        'app.kubernetes.io/name': cockroachdb.metadata.name + '-public',
      },
    },
    spec: {
      ports: [
        { name: name, port: cockroachdb.expose[name], targetPort: cockroachdb.expose[name] }
        for name in std.objectFields(cockroachdb.expose)
      ],
      selector: cockroachdb.metadata.labels,
    },
  },
  service: {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: cockroachdb.metadata {
      annotations: {
        'service.alpha.kubernetes.io/tolerate-unready-endpoints': 'true',
      },
    },
    spec: {
      clusterIP: 'None',
      publishNotReadyAddresses: true,
      ports: [
        { name: name, port: cockroachdb.expose[name], targetPort: cockroachdb.expose[name] }
        for name in std.objectFields(cockroachdb.expose)
      ],
      selector: cockroachdb.metadata.labels,
    },
  },
  statefulSet: {
    apiVersion: 'apps/v1',
    kind: 'StatefulSet',
    metadata: cockroachdb.metadata,
    spec: {
      podManagementPolicy: 'Parallel',
      replicas: cockroachdb.replicas,
      selector: {
        matchLabels: cockroachdb.metadata.labels,
      },
      serviceName: cockroachdb.metadata.name,
      template: {
        metadata: cockroachdb.metadata,
        spec: {
          containers: [
            {
              name: 'cockroachdb',
              image: cockroachdb.image,
              imagePullPolicy: 'IfNotPresent',
              podManagementPolicy: 'Parallel',
              args:: [
                'start',
                '--logtostderr=WARNING',
                '--insecure',
                '--advertise-host=$(hostname -f)',
                '--http-host=0.0.0.0',
                '--join=%s-0.%s.%s.svc' % [
                  cockroachdb.metadata.name,
                  cockroachdb.metadata.name,
                  cockroachdb.metadata.namespace,
                ],
                '--cache=25%',
                '--max-sql-memory=25%',
              ] + cockroachdb.extraArgs,
              command: [
                '/bin/bash',
                '-ecx',
                'exec /cockroach/cockroach %s' % std.join(' ', self.args),
              ],
              securityContext: {
                runAsUser: 65534,
                runAsGroup: 65534,
                runAsNonRoot: true,
                allowPrivilegeEscalation: false,
                seccompProfile: {
                  type: 'RuntimeDefault',
                },
                capabilities: {
                  drop: ['ALL'],
                },
              },
              env: [
                {
                  name: 'COCKROACH_CHANNEL',
                  value: 'kubernetes-insecure',
                },
              ],
              ports: [
                { name: name, containerPort: cockroachdb.expose[name] }
                for name in std.objectFields(cockroachdb.expose)
              ],
              resources: cockroachdb.resources,
              livenessProbe: {
                httpGet: {
                  path: '/health',
                  port: 'http',
                  scheme: 'HTTP',
                },
                initialDelaySeconds: 30,
                periodSeconds: 5,
              },
              readinessProbe: {
                failureThreshold: 2,
                httpGet: {
                  path: '/health?ready=1',
                  port: 'http',
                  scheme: 'HTTP',
                },
                initialDelaySeconds: 10,
                periodSeconds: 5,
              },
              volumeMounts: [
                { mountPath: '/cockroach/cockroach-data', name: 'datadir' },
              ],
            },
          ],
          terminationGracePeriodSeconds: 60,
          affinity: {
            podAntiAffinity: {
              preferredDuringSchedulingIgnoredDuringExecution: [
                {
                  podAffinityTerm: {
                    labelSelector: {
                      matchExpressions: [
                        { key: 'app.kubernetes.io/name', operator: 'In', values: [cockroachdb.metadata.name] },
                      ],
                    },
                    namespaces: [cockroachdb.metadata.namespace],
                    topologyKey: 'kubernetes.io/hostname',
                  },
                  weight: 100,
                },
              ],
            },
          },
          volumes: if std.objectHas(cockroachdb.storage, 'volumeClaimTemplate') then [
            { name: 'datadir', persistentVolumeClaim: { claimName: 'datadir' } },
          ] else [
            { name: 'datadir', emptyDir: {} },
          ],
        },
      },
      volumeClaimTemplates: if std.objectHas(cockroachdb.storage, 'volumeClaimTemplate') then [
        cockroachdb.storage.volumeClaimTemplate {
          metadata+: {
            name: 'datadir',
            namespace: cockroachdb.metadata.namespace,
          },
          spec+: {
            accessModes: ['ReadWriteOnce'],
          },
        },
      ] else [],
    },
  },
  podDisruptionBudget: {
    apiVersion: 'policy/v1',
    kind: 'PodDisruptionBudget',
    metadata: cockroachdb.metadata,
    spec: {
      maxUnavailable:  // (n-1)/2 if n>1
        if cockroachdb.replicas > 1 then
          std.floor((cockroachdb.replicas - 1) / 2)
        else 1,
      selector: {
        matchLabels: cockroachdb.metadata.labels,
      },
    },
  },

  jobInitialize: {
    apiVersion: 'batch/v1',
    kind: 'Job',
    metadata: cockroachdb.metadata,
    spec: {
      template: {
        metadata: {
          labels: cockroachdb.metadata.labels,
        },
        spec: {
          containers: [
            {
              name: 'cluster-init',
              image: cockroachdb.image,
              command: [
                '/cockroach/cockroach',
                'init',
                '--insecure',
                '--host=%s-0.%s.%s' % [
                  cockroachdb.metadata.name,
                  cockroachdb.metadata.name,
                  cockroachdb.metadata.namespace,
                ],
              ],
            },
          ],
          restartPolicy: 'OnFailure',
        },
      },
    },
  },

  serviceMonitor: {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'ServiceMonitor',
    metadata: cockroachdb.metadata {
      labels+: {
        prometheus: 'k8s',
      },
    },
    spec: {
      endpoints: [
        {
          port: 'http',
          path: '/_status/vars',
          metricRelabelings: [
            {
              // prefix all metric names with cockroachdb_
              sourceLabels: ['__name__'],
              targetLabel: '__name__',
              replacement: 'cockroachdb_${1}',
            },
          ],
        },
      ],
      namespaceSelector: {
        matchNames: [cockroachdb.metadata.namespace],
      },
      selector: {
        matchLabels: cockroachdb.metadata.labels,
      },
    },
  },

  // TODO: Add backups to object storage via CronJob and Minio
}
