#!/bin/bash
let Mike=0
let Nick=0
for i in {1..200}
do
 
    if (((2 * $i+15) - ($i+15) == 10 )); then
        # echo $i;
        let Mike=$i
        let Nick=$i/2
        break;
    fi
done
printf "%s %d\n" "Mike " "$Mike"
printf "%s %d\n" "Nick " "$Nick"

