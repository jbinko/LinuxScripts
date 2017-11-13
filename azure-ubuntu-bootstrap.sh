#!/bin/bash

set -e
[ "$DEBUG" == 'true' ] && set -x

PROXY_HOST="${1}"
PROXY_PORT="${2}"
NTP="${3}"

log() {
  echo "`date +'[%Y-%m-%d %H:%M:%S:%N %Z]'` $1"
}

bootstrap() {
  log ''
  log 'init'
  log ''

  # Company Proxy for walinuxagent
  log 'waagent.conf'
  log ''
  sed -i s,Service],Service]\\nEnvironment=\"https_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/walinuxagent.service
  sed -i s,Service],Service]\\nEnvironment=\"http_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/walinuxagent.service
  sed -i s,Service],Service]\\nEnvironment=\"HTTPS_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/walinuxagent.service
  sed -i s,Service],Service]\\nEnvironment=\"HTTP_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/walinuxagent.service

  # Company NTP
  log 'NTP'
  log ''
  echo NTP=$NTP >> /etc/systemd/timesyncd.conf

  log 'Restart of services'
  log ''
  systemctl daemon-reload
  systemctl restart walinuxagent
  systemctl restart systemd-timesyncd
    
  log 'close'
  log ''
}

log ''
log 'bootstrap start'
log '--------------------------------------------------'

bootstrap

log ''
log 'bootstrap done'
log ''
