#!/bin/bash

# set from=lhjldh860404@163.com
# set smtp=smtp.163.com
# set smtp-auth-user=lhjldh860404@163.com
# set smtp-auth-password=BYEIJBWZLNPAIEYG
# set smtp-auth=login

echo 'content...' |  s-nail -v -s "subject" -a foo.txt \
-S smtp="smtps://smtp.163.com:465"  \
-S smtp-use-starttls  \
-S smtp-auth=login  \
-S smtp-auth-user="lhjldh860404@163.com" \
-S smtp-auth-password="BYEIJBWZLNPAIEYG" \
-S ssl-verify=ignore  yiqing.hsu@gmail.com
