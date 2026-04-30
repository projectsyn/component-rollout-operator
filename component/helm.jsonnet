local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.rollout_operator;
local isOpenshift = std.member([ 'openshift4', 'oke' ], inv.parameters.facts.distribution);

local values = {
  global: {
    commonLabels: {
      'app.kubernetes.io/managed-by': 'commodore',
      'app.kubernetes.io/name': 'rollout-operator',
    },
  },
  image: {
    registry: params.images.rolloutOperator.registry,
    repository: params.images.rolloutOperator.repository,
    [if std.objectHas(params.images.rolloutOperator, 'tag') then 'tag']: params.images.rolloutOperator.tag,
  },
  resources: params.resources,
  webhooks: {
    [key]: params.webhooks[key]
    for key in std.objectFields(params.webhooks)
    if key != 'namespaceSelector'
  },
  namespaceSelector: params.webhooks.namespaceSelector,
  [if !isOpenshift then 'podSecurityContext']: {
    fsGroup: 10001,
    runAsGroup: 10001,
    runAsNonRoot: true,
    runAsUser: 10001,
    seccompProfile: {
      type: 'RuntimeDefault',
    },
  },
  securityContext: {
    readOnlyRootFilesystem: true,
    capabilities: {
      drop: [ 'ALL' ],
    },
    allowPrivilegeEscalation: false,
  },
  serviceMonitor: {
    enabled: params.monitoring,
  },
};

{
  'values-component': values,
  'values-overrides': params.helmValues,
}
