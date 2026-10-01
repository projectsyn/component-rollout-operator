// main template for rollout-operator
local alertpatching = import 'lib/alert-patching.libsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local prom = import 'lib/prom.libsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.rollout_operator;
local isOpenshift = std.member([ 'openshift4', 'oke' ], inv.parameters.facts.distribution);

local namespace = {
  apiVersion: 'v1',
  kind: 'Namespace',
  metadata: {
    labels: {
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': params.namespace,
      [if isOpenshift then 'openshift.io/cluster-monitoring']: 'true',
    },
    name: params.namespace,
  },
};

local prometheusRules = prom.generateRules('rollout-operator', { 'rollout-operator.rules': params.alerts.rules }) {
  metadata+: {
    labels+: {
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': 'rollout-operator',
    },
    namespace: params.namespace,
  },
};

local has_monitoring = std.member(inv.applications, 'prometheus') || std.member(inv.applications, 'openshift4-monitoring');
local has_alerts = std.length(params.alerts.rules) > 0;

// Define outputs below
{
  '00_namespace': namespace,
  [if params.monitoring && has_monitoring && has_alerts then '20_prometheus_rule']: prometheusRules,
}
