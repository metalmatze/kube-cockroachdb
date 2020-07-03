local k = (import 'main.libsonnet');

{
  groups: k.prometheusAlerts.groups + k.prometheusRules.groups,
}
