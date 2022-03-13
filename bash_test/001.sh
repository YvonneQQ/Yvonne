#!/bin/bash
printf "%s %s\n" "Kernel Release:" "$(uname -r)"
printf "%s %s\n" "Bash Version:" "$(bash -version | grep bash)"
printf "%s %s M\n" "Free Storage:" "$(df -m / | awk '/\//{print $4}')"
printf "%s %s M\n" "Free Storage:" "$(free -m | awk '/Mem/{print $4}')"

for n in `seq 10`
do
        name=$(echo $RANDOM|md5sum|tr ["0-9"] ["a-j"] |cut -c 2-11)
        touch ~/$(echo $name)_test.txt
done
printf "%s %s\n" "Total Files in any pwd:" "$(ls -l ~ | grep '^-' | wc -l)"
printf "%s %s\n" "IP Address:" "$(ifconfig | grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d 'addr:')"
printf "%s \n%s\n" "Interface(s) is/are active:" "$(ifconfig | awk -v RS="" '/MULTICAST/ && /UP/ && /RUNNING/ && /BROADCAST/ {print substr($1, 0, length($1)-1)}')"
