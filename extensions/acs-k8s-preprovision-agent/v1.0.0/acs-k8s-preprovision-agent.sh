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
  log 'waagent.conf'
  log ''
  #sudo sh -c 'sed -i s,Logs.Verbose=n,Logs.Verbose=y,g /etc/waagent.conf'
  sudo sh -c 'sed -i /HttpProxy.Host/s/^#//g /etc/waagent.conf'
  sudo sh -c 'sed -i /HttpProxy.Port/s/^#//g /etc/waagent.conf'
  sudo sh -c 'sed -i s,HttpProxy.Host=None,HttpProxy.Host=http://$PROXY_HOST,g /etc/waagent.conf'
  sudo sh -c 'sed -i s,HttpProxy.Port=None,HttpProxy.Port=$PROXY_PORT,g /etc/waagent.conf'
  
  # Company NTP
  log 'NTP'
  log ''
  sudo sh -c "echo NTP=$NTP >> /etc/systemd/timesyncd.conf"
  sudo service systemd-timesyncd restart

  log 'done'
  log ''
  
  log 'Restarting walinuxagent ....'
  log ''
  sudo systemctl restart walinuxagent.service
  log 'daemon-reload ....'
  log ''
  sudo systemctl daemon-reload
}

log ''
log 'acs-k8s-preprovision-agent'
log '--------------------------------------------------'

preprovision

log ''
log 'done'
log ''
