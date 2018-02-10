#!/bin/bash

set -e
[ "$DEBUG" == 'true' ] && set -x

ADDR_RANGE_VNET="${1}"
ADDR_RANGE_ONPREM="${2}"
IP_ADDR_ONPREM_DNS1="${3}"
IP_ADDR_ONPREM_DNS2="${4}"
DNS_SUFFIX=$(hostname -d)

log() {
  echo "`date +'[%Y-%m-%d %H:%M:%S:%N %Z]'` $1"
}

bootstrap() {
  log ''
  log 'init'
  log ''

  # install DNS server components
  apt-get update -y
  apt-get install bind9 -y
  apt-get install dnsutils

  # backup original config files
  cp /etc/bind/named.conf.local /etc/bind/named.conf.local.orig
  cp /etc/bind/named.conf.options /etc/bind/named.conf.options.orig

  # Name resolution between a virtual network and a connected on-premises network
  echo 'acl goodclients {' > /etc/bind/named.conf.options
  echo '   '$ADDR_RANGE_VNET'; # IP address range of the virtual network' >> /etc/bind/named.conf.options
  echo '   '$ADDR_RANGE_ONPREM'; # IP address range of the on-premises network' >> /etc/bind/named.conf.options
  echo '   localhost;' >> /etc/bind/named.conf.options
  echo '   localnets;' >> /etc/bind/named.conf.options
  echo '};' >> /etc/bind/named.conf.options
  echo '' >> /etc/bind/named.conf.options
  echo 'options {' >> /etc/bind/named.conf.options
  echo '   directory "/var/cache/bind";' >> /etc/bind/named.conf.options
  echo '' >> /etc/bind/named.conf.options
  echo '   recursion yes;' >> /etc/bind/named.conf.options
  echo '' >> /etc/bind/named.conf.options
  echo '   allow-query { goodclients; };' >> /etc/bind/named.conf.options
  echo '' >> /etc/bind/named.conf.options
  echo '   forwarders {' >> /etc/bind/named.conf.options
  echo '      '$IP_ADDR_ONPREM_DNS1'; # IP address of the on-premises DNS server 1' >> /etc/bind/named.conf.options
  echo '      '$IP_ADDR_ONPREM_DNS2'; # IP address of the on-premises DNS server 2' >> /etc/bind/named.conf.options
  echo '   };' >> /etc/bind/named.conf.options
  echo '' >> /etc/bind/named.conf.options
  echo '   dnssec-validation auto;' >> /etc/bind/named.conf.options
  echo '' >> /etc/bind/named.conf.options
  echo '   auth-nxdomain no; # conform to RFC1035' >> /etc/bind/named.conf.options
  echo '   listen-on { any; };' >> /etc/bind/named.conf.options
  echo '};' >> /etc/bind/named.conf.options

  # This configuration routes all DNS requests for the DNS suffix of the virtual network to the Azure recursive resolver.
  echo 'zone "'$DNS_SUFFIX'" {' > /etc/bind/named.conf.local
  echo '   type forward;' >> /etc/bind/named.conf.local
  echo '   forwarders {168.63.129.16;}; # The Azure recursive resolver' >> /etc/bind/named.conf.local
  echo '};' >> /etc/bind/named.conf.local

  # check config
  named-checkconf
  
  # restart DNS server
  service bind9 restart
    
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
