// main template for rollout-operator
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
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

// Define outputs below
{
  '00_namespace': namespace,
  [if params.monitoring then '20_prometheus_rule']: prometheusRules,
}
