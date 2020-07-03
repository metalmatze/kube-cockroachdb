local k = (import 'mixin.libsonnet');

{
  groups: k.prometheusAlerts.groups + k.prometheusRules.groups,
}
