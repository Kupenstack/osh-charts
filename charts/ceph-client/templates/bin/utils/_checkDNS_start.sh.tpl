#!/bin/bash

{{/*
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/}}

set -xe

{{ include "ceph-client.snippets.mon_host_from_k8s_ep" . }}

function check_mon_dns {
  DNS_CHECK=$(getent hosts ceph-mon | head -n1)
  PODS=$(kubectl get pods --namespace=${NAMESPACE} --selector=application=ceph --field-selector=status.phase=Running \
         --output=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep -E 'ceph-mon|ceph-osd|ceph-mgr|ceph-mds')
  ENDPOINT=$(mon_host_from_k8s_ep "${NAMESPACE}" ceph-mon-discovery)

  if [[ ${PODS} == "" || "${ENDPOINT}" == "" ]]; then
    echo "Something went wrong, no PODS or ENDPOINTS are available!"
  elif [[ ${DNS_CHECK} == "" ]]; then
    for POD in ${PODS}; do
      kubectl exec -t ${POD} --namespace=${NAMESPACE} -- \
      sh -c -e "/tmp/utils-checkDNS.sh "${ENDPOINT}""
    done
  else
    for POD in ${PODS}; do
      kubectl exec -t ${POD} --namespace=${NAMESPACE} -- \
      sh -c -e "/tmp/utils-checkDNS.sh up"
    done
  fi
}

function watch_mon_dns {
  while [ true ]; do
    echo "checking DNS health"
    check_mon_dns || true
    echo "sleep 300 sec"
    sleep 300
  done
}

watch_mon_dns

exit
