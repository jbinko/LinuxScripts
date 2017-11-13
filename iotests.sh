#!/bin/bash

echo 'Testing Azure Temp Drive /mnt  /dev/sdb1 ......'
echo '-----------------------------------------------'

#Test #1
sudo dd if=/dev/zero of=/mnt/test1.img bs=1G count=1 oflag=dsync
#Test #2
sudo dd if=/dev/zero of=/mnt/test2.img bs=512 count=1000 oflag=dsync
#Test #3
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches
time dd if=/mnt/test1.img of=/dev/null bs=8k
#Test #4
sudo hdparm -Tt /dev/sdb1

echo '-----------------------------------------------'
echo 'done'
