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
  #sudo sh -c "sed 's/Logs.Verbose=n/Logs.Verbose=y/g' /etc/waagent.conf > waagent.conf"
  #sudo mv waagent.conf /etc/waagent.conf
  sudo sh -c "sed 's/#HttpProxy.Host=None/HttpProxy.Host=http://$PROXY_HOST/g' /etc/waagent.conf > waagent.conf"
  sudo mv waagent.conf /etc/waagent.conf
  sudo sh -c "sed 's/#HttpProxy.Port=None/HttpProxy.Port=$PROXY_PORT/g' /etc/waagent.conf > waagent.conf"
  sudo mv waagent.conf /etc/waagent.conf
  
  # Company NTP
  sudo sh -c "echo NTP=$NTP >> /etc/systemd/timesyncd.conf"
  sudo service systemd-timesyncd restart

  # Copy cluster certificates
  sudo cp /etc/kubernetes/certs/*.crt /usr/local/share/ca-certificates
  sudo update-ca-certificates
  sudo dpkg-reconfigure -f noninteractive ca-certificates
    
  log 'done'
  log ''
  
  log 'Restarting walinuxagent ....'
  log ''
  sudo service walinuxagent restart
  log 'daemon-reload ....'
  log ''
  sudo systemctl daemon-reload
}

log ''
log 'acs-k8s-preprovision-master'
log '--------------------------------------------------'

preprovision

log ''
log 'done'
log ''
