#!/bin/bash

set -e
[ "$DEBUG" == 'true' ] && set -x

PROXY="${1}"

log() {
  echo "`date +'[%Y-%m-%d %H:%M:%S:%N %Z]'` $1"
}

adjust_manifests() {
  log ''
  log 'init'
  log ''

  # Inject proxy to system manifests
  sed -i "s|command:|env:\\n        - name: https_proxy\\n          value: $PROXY\\n        - name: http_proxy\\n          value: $PROXY\\n        - name: no_proxy\\n          value: localhost,127.0.0.1\\n      command:|g" /etc/kubernetes/manifests/kube-controller-manager.yaml
  sed -i "s|--v=2|--v=1|g" /etc/kubernetes/manifests/kube-controller-manager.yaml
  #sed -i "s|command:|env:\\n        - name: https_proxy\\n          value: $PROXY\\n        - name: http_proxy\\n          value: $PROXY\\n        - name: no_proxy\\n          value: localhost,127.0.0.1\\n      command:|g" /etc/kubernetes/manifests/kube-apiserver.yaml
  sed -i "s|--v=4|--v=1|g" /etc/kubernetes/manifests/kube-apiserver.yaml
  #sed -i "s|resources:|env:\\n    - name: https_proxy\\n      value: $PROXY\\n    - name: http_proxy\\n      value: $PROXY\\n    - name: no_proxy\\n      value: localhost,127.0.0.1\\n    resources:|g" /etc/kubernetes/manifests/kube-addon-manager.yaml
  sed -i "s|--v=2|--v=1|g" /etc/kubernetes/manifests/kube-addon-manager.yaml
  #sed -i "s|command:|env:\\n        - name: https_proxy\\n          value: $PROXY\\n        - name: http_proxy\\n          value: $PROXY\\n        - name: no_proxy\\n          value: localhost,127.0.0.1\\n      command:|g" /etc/kubernetes/manifests/kube-scheduler.yaml
  sed -i "s|--v=2|--v=1|g" /etc/kubernetes/manifests/kube-scheduler.yaml

  log ''
  log 'close'
  log ''
}

log ''
log 'acs-k8s-manifests-env.sh start'
log '--------------------------------------------------'

adjust_manifests

log ''
log 'acs-k8s-manifests-env.sh done'
log ''
