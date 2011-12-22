#!/bin/bash

set -x
set -e

export PATH=$PATH:/usr/groups/xencore/systems/bin
PWD=`pwd`
HOSTS=$@
USER=$(whoami)
PXETARGET="pxelinux.cfg/kronos-ubuntu-staging-as"
PXEDIR="/usr/groups/netboot/${USER}"

for HOST in ${HOSTS[@]}; do
	ln -sf ${PXETARGET} ${PXEDIR}/${HOST}
	echo "Rebooting host"

	xenuse --reboot -f ${HOST}
	xenuse --reboot -f ${HOST}
done

sleep 300

for HOST in ${HOSTS[@]}; do
	ln -sf default ${PXEDIR}/${HOST}
done

echo "Now waiting for SSH to be up"

ssh_timeout="1200"
ssh_interval="10"
ssh_time=0;
HOST=${HOSTS[0]}

while ! echo | nc ${HOST} 22 && [[ $ssh_time -lt $ssh_timeout ]] ; do
   ssh_time=$(($ssh_time+$ssh_interval))
   sleep $ssh_interval
done

if [ $ssh_time -ge $ssh_timeout ]; then
   echo "Timed out waiting for SSH to start" 
   exit 1
fi

echo "SSH is up"

for HOST in ${HOSTS[@]}; do
	#sshpass -p xenroot ssh root@${HOST} -o StrictHostKeyChecking=no echo
	sshpass -p xenroot ssh-copy-id root@${HOST} -o StrictHostKeyChecking=no
done

MASTER=${HOST[0]}

scp ./run_test_suite.sh ${MASTER}:
ssh ${MASTER} bash ./run_test_suite.sh &> test_${MASTER}.log
