{
  prometheusRules+:: {
    groups+: [
      {
        name: 'cockroachdb.rules',
        rules: [
          {
            record: 'node:cockroachdb_capacity:sum',
            expr: |||
              sum without(store) (cockroachdb_capacity{%(cockroachdbSelector)s})
            ||| % $._config,
          },
          {
            record: 'cluster:cockroachdb_capacity:sum',
            expr: |||
              sum without(instance) (node:cockroachdb_capacity:sum{%(cockroachdbSelector)s})
            ||| % $._config,
          },
          {
            record: 'node:cockroachdb_capacity_available:sum',
            expr: |||
              sum without(store) (cockroachdb_capacity_available{%(cockroachdbSelector)s})
            ||| % $._config,
          },
          {
            record: 'cluster:cockroachdb_capacity_available:sum',
            expr: |||
              sum without(instance) (node:cockroachdb_capacity_available:sum{%(cockroachdbSelector)s})
            ||| % $._config,
          },
          {
            record: ':cockroachdb_capacity_available:ratio',
            expr: |||
              cockroachdb_capacity_available{%(cockroachdbSelector)s} / cockroachdb_capacity{%(cockroachdbSelector)s}
            ||| % $._config,
          },
          {
            record: 'node:cockroachdb_capacity_available:ratio',
            expr: |||
              node:cockroachdb_capacity_available:sum{%(cockroachdbSelector)s} / node:cockroachdb_capacity:sum{%(cockroachdbSelector)s}
            ||| % $._config,
          },
          {
            record: 'cluster:cockroachdb_capacity_available:ratio',
            expr: |||
              cluster:cockroachdb_capacity_available:sum{%(cockroachdbSelector)s} / cluster:cockroachdb_capacity:sum{%(cockroachdbSelector)s}
            ||| % $._config,
          },
        ],
      },
    ],
  },
}
