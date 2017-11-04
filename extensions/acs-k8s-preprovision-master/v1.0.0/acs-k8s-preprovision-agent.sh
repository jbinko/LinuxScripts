#!/bin/bash
# https://raw.githubusercontent.com/Azure/acs-engine/master/extensions/microsoft-oms-agent-k8s/v1/microsoft-oms-agent-k8s.sh

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

  # Install jq to obtain the input parameters
  log 'Installing jq'
  log ''
  sudo apt-get -y install jq
  log ''

  log 'done'
  log ''
}

cleanup_script_dependencies() {
  log ''
  log 'Removing script dependencies'
  log ''

  log 'Removing jq'
  log ''
  sudo apt-get -y remove jq
  log ''

  log 'done'
  log ''
}

preprovision() {
  log ''
  log 'preprovision agent'
  log ''

  #local wsid=$(get_param 'WSID')
  #local key=$(get_param 'KEY')
  
  log 'done'
  log ''
}

log ''
log 'acs-k8s-preprovision-agent'
log '--------------------------------------------------'

install_script_dependencies
preprovision
cleanup_script_dependencies

log ''
log 'done'
log ''
