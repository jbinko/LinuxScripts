#!/bin/bash

set -e
[ "$DEBUG" == 'true' ] && set -x

PROXY_HOST="${1}"
PROXY_PORT="${2}"
NTP="${3}"

log() {
  echo "`date +'[%Y-%m-%d %H:%M:%S:%N %Z]'` $1"
}

preprovision() {
  log ''
  log 'preprovision master'
  log ''

  # https://github.com/kubernetes/kops/issues/2481

  # Company Proxy for walinuxagent
  sudo sh -c "sed '/\[Service\]/a Environment=http_proxy=http://$PROXY_HOST:$PROXY_PORT' /lib/systemd/system/walinuxagent.service > walinuxagent.service"
  sudo mv walinuxagent.service /lib/systemd/system/walinuxagent.service
  sudo sh -c "sed '/\[Service\]/a Environment=https_proxy=http://$PROXY_HOST:$PROXY_PORT' /lib/systemd/system/walinuxagent.service > walinuxagent.service"
  sudo mv walinuxagent.service /lib/systemd/system/walinuxagent.service
  sudo sh -c "echo HttpProxy.Host=http://$PROXY_HOST >> /etc/waagent.conf"
  sudo sh -c "echo HttpProxy.Port=$PROXY_PORT >> /etc/waagent.conf"
  sudo systemctl daemon-reload
  sudo service walinuxagent restart 
  
  # Company Proxy for APT
  sudo sh -c "echo 'Acquire::http::proxy \"http://$PROXY_HOST:$PROXY_PORT/\";' >> /etc/apt/apt.conf.d/95proxies"
  sudo sh -c "echo 'Acquire::https::proxy \"http://$PROXY_HOST:$PROXY_PORT/\";' >> /etc/apt/apt.conf.d/95proxies"
  sudo sh -c "echo 'Acquire::ftp::proxy \"http://$PROXY_HOST:$PROXY_PORT/\";' >> /etc/apt/apt.conf.d/95proxies"

  # Company NTP
  sudo sh -c "echo NTP=$NTP >> /etc/systemd/timesyncd.conf"
  sudo service systemd-timesyncd restart

  # APT - AllowUnauthenticated
  sudo sh -c "echo 'APT::Get::AllowUnauthenticated \"true\";' >> /etc/apt/apt.conf.d/99myown"

  # Install Utilities
  sudo apt-get -y install mc

  # Copy cluster certificates
  sudo cp /etc/kubernetes/certs/*.crt /usr/local/share/ca-certificates
  sudo update-ca-certificates
  sudo dpkg-reconfigure -f noninteractive ca-certificates
    
  log 'done'
  log ''
}

log ''
log 'acs-k8s-preprovision-master'
log '--------------------------------------------------'

preprovision

log ''
log 'done'
log ''
