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

  local proxy=$(get_param 'Proxy')
  local NTP=$(get_param 'NTP')

  echo "NTP="$NTP >> /etc/systemd/timesyncd.conf

  #echo "export http_proxy=http://"$proxy >> /etc/environment
  #echo "export https_proxy=http://"$proxy >> /etc/environment
  #echo "export ftp_proxy=http://"$proxy >> /etc/environment
  
  #echo "Acquire::http::proxy \"http://"$proxy"\"" >> /etc/apt/apt.conf.d/95proxies
  #echo "Acquire::https::proxy \"http://"$proxy"\"" >> /etc/apt/apt.conf.d/95proxies
  #echo "Acquire::ftp::proxy \"ftp://"$proxy"\"" >> /etc/apt/apt.conf.d/95proxies

  #echo "APT::Get::AllowUnauthenticated \"true\"" >> /etc/apt/apt.conf.d/99myown
    
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
