#!/bin/bash

set -e
[ "$DEBUG" == 'true' ] && set -x

log() {
  echo "`date +'[%Y-%m-%d %H:%M:%S:%N %Z]'` $1"
}

bootstrap() {
  log ''
  log 'init'
  log ''




  sudo apt-get update -y
  sudo apt-get install bind9 -y




    
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
