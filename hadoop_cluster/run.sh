#!/bin/bash

# Deploy master
ansible-playbook -K 01-master.yml

# Deploy nodes
#master_ip:  your hadoop master ip
#master_hostname: your hadoop master hostname

ansible-playbook -K 02-nodes.yml -e "master_ip=$(cat hosts | grep "master ansible" hosts | cut -d= -f2) master_hostname=hadoop-master"