#!/bin/bash
# sshpass -p "root" ssh -t u20@192.168.230.129 "df -h"
USERNAME=u20
HOSTS="192.168.230.129"
pass='root'
sshpass -p $pass ssh $USERNAME@$HOSTS "echo $pass | sudo -S reboot"

