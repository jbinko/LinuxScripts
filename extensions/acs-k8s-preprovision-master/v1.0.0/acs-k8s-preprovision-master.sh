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
  log 'waagent.conf'
  log ''
  #sed -i s,Logs.Verbose=n,Logs.Verbose=y,g /etc/waagent.conf
  # HttpProxy.Host & HttpProxy.Port doesn't work as expected
  #sed -i s,#HttpProxy.Host=None,HttpProxy.Host=http://$PROXY_HOST,g /etc/waagent.conf
  #sed -i s,#HttpProxy.Port=None,HttpProxy.Port=$PROXY_PORT,g /etc/waagent.conf
  sed -i s,Service],Service]\\nEnvironment=\"https_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/walinuxagent.service
  sed -i s,Service],Service]\\nEnvironment=\"http_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/walinuxagent.service
  sed -i s,Service],Service]\\nEnvironment=\"HTTPS_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/walinuxagent.service
  sed -i s,Service],Service]\\nEnvironment=\"HTTP_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/walinuxagent.service

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

  sed -i s,Service],Service]\\nEnvironment=\"https_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.service
  sed -i s,Service],Service]\\nEnvironment=\"http_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.service
  sed -i s,Service],Service]\\nEnvironment=\"HTTPS_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.service
  sed -i s,Service],Service]\\nEnvironment=\"HTTP_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.service

  sed -i s,Service],Service]\\nEnvironment=\"https_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.system-shutdown.service
  sed -i s,Service],Service]\\nEnvironment=\"http_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.system-shutdown.service
  sed -i s,Service],Service]\\nEnvironment=\"HTTPS_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.system-shutdown.service
  sed -i s,Service],Service]\\nEnvironment=\"HTTP_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/snapd.system-shutdown.service

  # Company NTP
  log 'NTP'
  log ''
  echo NTP=$NTP >> /etc/systemd/timesyncd.conf

  # Copy cluster certificates
  log 'certificates'
  log ''
  sudo cp /etc/kubernetes/certs/*.crt /usr/local/share/ca-certificates
  sudo update-ca-certificates
  sudo dpkg-reconfigure -f noninteractive ca-certificates

  log 'Restart of services'
  log ''
  # https://docs.docker.com/engine/admin/systemd/
  systemctl daemon-reload
  systemctl restart walinuxagent
  systemctl restart systemd-timesyncd
  systemctl restart snapd
  snap refresh
    
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
