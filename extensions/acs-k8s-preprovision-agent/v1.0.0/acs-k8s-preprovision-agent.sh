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

  log 'done'
  log ''
}

preprovision() {
  log ''
  log 'preprovision agent'
  log ''

  # https://github.com/kubernetes/kops/issues/2481

  local proxyHost=$(get_param 'ProxyHost')
  local proxyPort=$(get_param 'ProxyPort')
  local NTP=$(get_param 'NTP')

  local proxyHost=$(get_param 'ProxyHost')
  local proxyPort=$(get_param 'ProxyPort')
  local NTP=$(get_param 'NTP')

  sudo sed "/\[Service\]/a Environment=http_proxy=http://$proxyHost:$proxyPort" /lib/systemd/system/walinuxagent.service
  sudo sed "/\[Service\]/a Environment=https_proxy=http://$proxyHost:$proxyPort" /lib/systemd/system/walinuxagent.service
  sudo service walinuxagent restart
  
  sudo echo "NTP="$NTP >> /etc/systemd/timesyncd.conf
  sudo service systemd-timesyncd restart







  
  ##echo "http_proxy=http://"$proxy >> /etc/environment
  ##echo "https_proxy=http://"$proxy >> /etc/environment
  ##echo "ftp_proxy=http://"$proxy >> /etc/environment

  ##touch /etc/profile.d/acsenv.sh
  ##chmod +rwxrwxrwx /etc/profile.d/acsenv.sh
  ##echo "export http_proxy=http://"$proxy >> /etc/profile.d/acsenv.sh
  ##echo "export https_proxy=http://"$proxy >> /etc/profile.d/acsenv.sh
  ##echo "export ftp_proxy=http://"$proxy >> /etc/profile.d/acsenv.sh
  ##source /etc/profile.d/acsenv.sh

  ##echo "Acquire::http::proxy \"http://"$proxy"\";" >> /etc/apt/apt.conf.d/95proxies
  ##echo "Acquire::https::proxy \"http://"$proxy"\";" >> /etc/apt/apt.conf.d/95proxies
  ##echo "Acquire::ftp::proxy \"ftp://"$proxy"\";" >> /etc/apt/apt.conf.d/95proxies

  ##echo "APT::Get::AllowUnauthenticated \"true\";" >> /etc/apt/apt.conf.d/99myown
  
  ##echo "DefaultEnvironment=\"http_proxy=http://"${proxy}"\" \"https_proxy=http://"${proxy}"\" \"ftp_proxy=http://"${proxy}"\"" >> /etc/systemd/system.conf

  #MC
  sudo apt-get -y install mc

  #echo "export http_proxy=\"http://"$proxy"\"" >> /etc/default/docker
  #echo "export https_proxy=\"http://"$proxy"\"" >> /etc/default/docker
  #echo "export ftp_proxy=\"http://"$proxy"\"" >> /etc/default/docker
    
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
