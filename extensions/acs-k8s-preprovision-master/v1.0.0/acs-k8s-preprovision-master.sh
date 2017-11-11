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
  sed -i s,#HttpProxy.Host=None,HttpProxy.Host=http://$PROXY_HOST,g /etc/waagent.conf
  sed -i s,#HttpProxy.Port=None,HttpProxy.Port=$PROXY_PORT,g /etc/waagent.conf
  #sed -i s,Service],Service]\\nEnvironment=\"https_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/walinuxagent.service
  #sed -i s,Service],Service]\\nEnvironment=\"http_proxy=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/walinuxagent.service
  #sed -i s,Service],Service]\\nEnvironment=\"HTTPS_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/walinuxagent.service
  #sed -i s,Service],Service]\\nEnvironment=\"HTTP_PROXY=http:\/\/$PROXY_HOST:$PROXY_PORT/\",g /lib/systemd/system/walinuxagent.service
  sed -i s,Service],Service]\\nEnvironment=\"no_proxy=blob.core.windows.net\",g /lib/systemd/system/walinuxagent.service
  sed -i s,Service],Service]\\nEnvironment=\"NO_PROXY=blob.core.windows.net\",g /lib/systemd/system/walinuxagent.service






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

  # Copy cluster certificates
  log 'certificates'
  log ''
  sudo cp /etc/kubernetes/certs/*.crt /usr/local/share/ca-certificates
  sudo update-ca-certificates
  sudo dpkg-reconfigure -f noninteractive ca-certificates
    
  log 'done'
  log ''
  
  log 'Restarting walinuxagent ....'
  log ''
  sudo systemctl restart walinuxagent.service
  log 'daemon-reload ....'
  log ''
  sudo systemctl daemon-reload

  # https://docs.docker.com/engine/admin/systemd/
  sudo systemctl show --property=Environment walinuxagent.service
}

log ''
log 'acs-k8s-preprovision-master'
log '--------------------------------------------------'

preprovision

log ''
log 'done'
log ''
