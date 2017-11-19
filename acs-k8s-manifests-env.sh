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

  file="/etc/kubernetes/manifests/kube-controller-manager.yaml"
  if [ -f "$file" ]
  then
    # Inject proxy to system manifests
	sed -i "s|command:|env:\\n        - name: https_proxy\\n          value: $PROXY\\n        - name: http_proxy\\n          value: $PROXY\\n        - name: no_proxy\\n          value: localhost,127.0.0.1\\n      command:|g" $file
	sed -i "s|--v=2|--v=4|g" $file
  fi

  file="/etc/kubernetes/manifests/kube-apiserver.yaml"
  if [ -f "$file" ]
  then
    #sed -i "s|command:|env:\\n        - name: https_proxy\\n          value: $PROXY\\n        - name: http_proxy\\n          value: $PROXY\\n        - name: no_proxy\\n          value: localhost,127.0.0.1\\n      command:|g" $file
    sed -i "s|--v=4|--v=1|g" $file
  fi
  
  file="/etc/kubernetes/manifests/kube-addon-manager.yaml"
  if [ -f "$file" ]
  then
    #sed -i "s|resources:|env:\\n    - name: https_proxy\\n      value: $PROXY\\n    - name: http_proxy\\n      value: $PROXY\\n    - name: no_proxy\\n      value: localhost,127.0.0.1\\n    resources:|g" $file
    sed -i "s|--v=2|--v=1|g" $file
  fi

  file="/etc/kubernetes/manifests/kube-scheduler.yaml"
  if [ -f "$file" ]
  then
    #sed -i "s|command:|env:\\n        - name: https_proxy\\n          value: $PROXY\\n        - name: http_proxy\\n          value: $PROXY\\n        - name: no_proxy\\n          value: localhost,127.0.0.1\\n      command:|g" $file
	sed -i "s|--v=2|--v=1|g" $file
  fi

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
