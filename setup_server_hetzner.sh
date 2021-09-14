#!/bin/bash -xe

HOST=$1

echo 'Installing image'
env ANSIBLE_HOST_KEY_CHECKING=False ansible $HOST -u root -a "/root/.oldroot/nfs/install/installimage -r yes -l 0 -i /root/.oldroot/nfs/install/../images/Ubuntu-2004-focal-64-minimal.tar.gz -g -t yes -G yes -a && shutdown -r now"

echo 'Bootstrapping Ansible'
