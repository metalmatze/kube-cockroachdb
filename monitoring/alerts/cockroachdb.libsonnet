{
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'cockroachdb',
        rules: [
          {
            alert: 'CockroachInstanceFlapping',
            expr: |||
              resets(cockroachdb_sys_uptime{%(cockroachdbSelector)s}[10m]) > 5
            ||| % $._config,
            'for': '1m',
            labels: {
              severity: 'warning',
            },
            annotations: {
              summary: 'CockroachDB instances have restarted in the last 10 minutes.',
              description: '{{ $labels.instance }} for cluster {{ $labels.cluster }} restarted {{ $value }} time(s) in 10m.',
            },
          },
          {
            alert: 'CockroachLivenessMismatch',
            expr: |||
              (cockroachdb_liveness_livenodes{%(cockroachdbSelector)s})
                !=
              ignoring(instance) group_left() (count by(cluster, job) (up{%(cockroachdbSelector)s} == 1))
            ||| % $._config,
            'for': '5m',
            labels: {
              severity: 'warning',
            },
            annotations: {
              summary: 'CockroachDB has liveness mismatches.',
              description: 'Liveness mismatch for {{ $labels.instance }}',
            },
          },
          {
            alert: 'CockroachVersionMismatch',
            expr: |||
              count by(cluster) (count_values by(tag, cluster) ("version", cockroachdb_build_timestamp{%(cockroachdbSelector)s})) > 1
            ||| % $._config,
            'for': '1h',
            labels: {
              severity: 'warning',
            },
            annotations: {
              summary: 'CockroachDB cluster is running different versions.',
              description: 'Cluster {{ $labels.cluster }} running {{ $value }} different versions',
            },
          },
          {
            alert: 'CockroachStoreDiskLow',
            // TODO: use predict_linear
            expr: |||
              :cockroachdb_capacity_available:ratio{%(cockroachdbSelector)s} < 0.15
            ||| % $._config,
            'for': '30m',
            labels: {
              severity: 'critical',
            },
            annotations: {
              summary: 'CockroachDB is at low disk capacity.',
              description: 'Store {{ $labels.store }} on node {{ $labels.instance }} at {{ $value }} available disk fraction',
            },
          },
          {
            alert: 'CockroachClusterDiskLow',
            // TODO: use predict_linear
            expr: |||
              cluster:cockroachdb_capacity_available:ratio{%(cockroachdbSelector)s} < 0.2
            ||| % $._config,
            'for': '30m',
            labels: {
              severity: 'critical',
            },
            annotations: {
              summary: 'CockroachDB cluster is at critically low disk capacity.',
              description: 'Cluster {{ $labels.cluster }} at {{ $value }} available disk fraction',
            },
          },
          // {
          //   alert: 'CockroachZeroSQLQps',
          //   expr: |||
          //     cockroachdb_sql_conns{%(cockroachdbSelector)s} > 0 and rate(cockroachdb_sql_query_count{%(cockroachdbSelector)s}[5m]) == 0
          //   ||| % $._config,
          //   'for': '10m',
          //   labels: {
          //     severity: 'critical',
          //   },
          //   annotations: {
          //     message: 'Instance {{ $labels.instance }} has SQL connections but no queries',
          //   },
          // },
          {
            alert: 'CockroachUnavailableRanges',
            expr: |||
              (sum by(instance, cluster) (cockroachdb_ranges_unavailable{%(cockroachdbSelector)s})) > 0
            ||| % $._config,
            'for': '10m',
            labels: {
              severity: 'critical',
            },
            annotations: {
              summary: 'CockroachDB has unavailable ranges.',
              description: 'Instance {{ $labels.instance }} has {{ $value }} unavailable ranges',
            },
          },
          {
            alert: 'CockroachNoLeaseRanges',
            expr: |||
              (sum by(instance, cluster) (cockroachdb_replicas_leaders_not_leaseholders{%(cockroachdbSelector)s})) > 0
            ||| % $._config,
            'for': '10m',
            labels: {
              severity: 'warning',
            },
            annotations: {
              summary: 'CockroachDB has ranges without leases.',
              description: 'Instance {{ $labels.instance }} has {{ $value }} ranges without leases',
            },
          },
          {
            alert: 'CockroachHighOpenFDCount',
            expr: |||
              cockroachdb_sys_fd_open{%(cockroachdbSelector)s} / cockroachdb_sys_fd_softlimit{%(cockroachdbSelector)s} > 0.8
            ||| % $._config,
            'for': '10m',
            labels: {
              severity: 'warning',
            },
            annotations: {
              summary: 'CockroachDB has too many open file descriptors.',
              description: 'Too many open file descriptors on {{ $labels.instance }}: {{ $value }} fraction used',
            },
          },
        ],
      },
    ],
  },
}
