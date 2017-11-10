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
  log 'preprovision agent'
  log ''

  # https://github.com/kubernetes/kops/issues/2481

  # Company Proxy for walinuxagent
  #sudo sh -c "sed 's/Logs.Verbose=n/Logs.Verbose=y/g' /etc/waagent.conf > waagent.conf"
  #sudo mv waagent.conf /etc/waagent.conf
  sudo sh -c "sed 's/#HttpProxy.Host=None/HttpProxy.Host=http://$PROXY_HOST/g' /etc/waagent.conf > waagent.conf"
  sudo mv waagent.conf /etc/waagent.conf
  sudo sh -c "sed 's/#HttpProxy.Port=None/HttpProxy.Port=$PROXY_PORT/g' /etc/waagent.conf > waagent.conf"
  sudo mv waagent.conf /etc/waagent.conf
  sudo systemctl daemon-reload
  
  # Company NTP
  sudo sh -c "echo NTP=$NTP >> /etc/systemd/timesyncd.conf"
  sudo service systemd-timesyncd restart

  log 'done'
  log ''

  log 'Restarting walinuxagent ....'
  log ''
  sudo service walinuxagent restart 
}

log ''
log 'acs-k8s-preprovision-agent'
log '--------------------------------------------------'

preprovision

log ''
log 'done'
log ''
