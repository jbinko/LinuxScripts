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
  #sed -i s,Logs.Verbose=n,Logs.Verbose=y,g /etc/waagent.conf
  sed -i s,#HttpProxy.Host=None,HttpProxy.Host=http://$PROXY_HOST,g /etc/waagent.conf
  sed -i s,#HttpProxy.Port=None,HttpProxy.Port=$PROXY_PORT,g /etc/waagent.conf
  sed -i s,Service],Service]\\nEnvironment=\"https_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/walinuxagent.service
  sed -i s,Service],Service]\\nEnvironment=\"http_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/walinuxagent.service
  sed -i s,Service],Service]\\nEnvironment=\"HTTPS_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/walinuxagent.service
  sed -i s,Service],Service]\\nEnvironment=\"HTTP_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/walinuxagent.service
  sed -i s,Service],Service]\\nEnvironment=\"no_proxy=blob.core.windows.net\",g /lib/systemd/system/walinuxagent.service
  sed -i s,Service],Service]\\nEnvironment=\"NO_PROXY=blob.core.windows.net\",g /lib/systemd/system/walinuxagent.service

  # Company Proxy for Docker - https://docs.docker.com/engine/admin/systemd/#httphttps-proxy
  log 'Docker http-proxy.conf'
  log ''
  mkdir -p /etc/systemd/system/docker.service.d
  echo '[Service]' >> /etc/systemd/system/docker.service.d/http-proxy.conf
  echo Environment="HTTP_PROXY=http://$PROXY_HOST:$PROXY_PORT/" >> /etc/systemd/system/docker.service.d/http-proxy.conf
  echo Environment="HTTPS_PROXY=http://$PROXY_HOST:$PROXY_PORT/" >> /etc/systemd/system/docker.service.d/http-proxy.conf
  echo Environment="http_proxy=http://$PROXY_HOST:$PROXY_PORT/" >> /etc/systemd/system/docker.service.d/http-proxy.conf
  echo Environment="https_proxy=http://$PROXY_HOST:$PROXY_PORT/" >> /etc/systemd/system/docker.service.d/http-proxy.conf
  echo Environment="NO_PROXY=localhost,127.0.0.1" >> /etc/systemd/system/docker.service.d/http-proxy.conf
  echo Environment="no_proxy=localhost,127.0.0.1" >> /etc/systemd/system/docker.service.d/http-proxy.conf

  # Company Proxy for Snapd
  log 'snapd service'
  log ''
  sed -i s,Service],Service]\\nEnvironment=\"https_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.refresh.service
  sed -i s,Service],Service]\\nEnvironment=\"http_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.refresh.service
  sed -i s,Service],Service]\\nEnvironment=\"HTTPS_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.refresh.service
  sed -i s,Service],Service]\\nEnvironment=\"HTTP_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.refresh.service

  sed -i s,Service],Service]\\nEnvironment=\"https_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.autoimport.service
  sed -i s,Service],Service]\\nEnvironment=\"http_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.autoimport.service
  sed -i s,Service],Service]\\nEnvironment=\"HTTPS_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.autoimport.service
  sed -i s,Service],Service]\\nEnvironment=\"HTTP_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.autoimport.service

  sed -i s,Service],Service]\\nEnvironment=\"https_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.refresh.timer
  sed -i s,Service],Service]\\nEnvironment=\"http_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.refresh.timer
  sed -i s,Service],Service]\\nEnvironment=\"HTTPS_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.refresh.timer
  sed -i s,Service],Service]\\nEnvironment=\"HTTP_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.refresh.timer

  sed -i s,Service],Service]\\nEnvironment=\"https_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.service
  sed -i s,Service],Service]\\nEnvironment=\"http_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.service
  sed -i s,Service],Service]\\nEnvironment=\"HTTPS_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.service
  sed -i s,Service],Service]\\nEnvironment=\"HTTP_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.service

  sed -i s,Service],Service]\\nEnvironment=\"https_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.socket
  sed -i s,Service],Service]\\nEnvironment=\"http_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.socket
  sed -i s,Service],Service]\\nEnvironment=\"HTTPS_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.socket
  sed -i s,Service],Service]\\nEnvironment=\"HTTP_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.socket

  sed -i s,Service],Service]\\nEnvironment=\"https_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/system-shutdown.service
  sed -i s,Service],Service]\\nEnvironment=\"http_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/system-shutdown.service
  sed -i s,Service],Service]\\nEnvironment=\"HTTPS_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/system-shutdown.service
  sed -i s,Service],Service]\\nEnvironment=\"HTTP_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/system-shutdown.service

  # Company NTP
  log 'NTP'
  log ''
  echo NTP=$NTP >> /etc/systemd/timesyncd.conf
  sudo service systemd-timesyncd restart

  log 'done'
  log ''

  log 'Async restart of services'
  log ''
  # https://docs.docker.com/engine/admin/systemd/
  sudo /bin/bash -c '( sleep 5; systemctl daemon-reload; systemctl restart walinuxagent.service; snap refresh; ) &'
}

log ''
log 'acs-k8s-preprovision-agent'
log '--------------------------------------------------'

preprovision

log ''
log 'done'
log ''
