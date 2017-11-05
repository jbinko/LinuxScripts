#!/bin/bash

set -e
[ "$DEBUG" == 'true' ] && set -x

parameters=$(echo $1 | base64 -d -)

log() {
  echo "`date +'[%Y-%m-%d %H:%M:%S:%N %Z]'` $1"
}

get_param() {
  local param=$1
  echo $(echo "$parameters" | jq ".$param" -r)
}

install_script_dependencies() {
  log ''
  log 'Installing script dependencies'
  log ''

  log 'done'
  log ''
}

cleanup_script_dependencies() {
  log ''
  log 'Removing script dependencies'
  log ''

  log 'done'
  log ''
}

extensionprovision() {
  log ''
  log 'extension provision master'
  log ''
    
  log 'done'
  log ''
}

log ''
log 'acs-k8s-extension-provision-master'
log '--------------------------------------------------'

install_script_dependencies
extensionprovision
cleanup_script_dependencies

log ''
log 'done'
log ''
