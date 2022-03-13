#!/bin/bash
birth="12/03/1997"
echo $birth
echo ${birth////} | sed "s/[0-9]/&\n/g" | awk '{sum += $1};END {print sum}'
