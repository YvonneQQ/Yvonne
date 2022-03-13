#!/bin/bash
read -p "enter a postal code > " post_code
echo "postal code: $post_code"
if [[ "$post_code" =~ ^[a-zA-Z0-9]{6}$ ]]; then
    echo "Canada"
elif [[ "$post_code" =~ ^[0-9]{5}$ ]] ; then
    echo "USA"
else
    echo "none"
fi