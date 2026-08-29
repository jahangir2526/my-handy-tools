#!/bin/bash
# Author: Jahangir Alam (jahangir2526@gmail.com)
# ./<name>.sh "<string1>" "<string2>"

VAR1="$1"
VAR2="$2"

if [ "$VAR1" = "$VAR2" ]; then
    echo "EQUAL"
else
    echo "NOT EQUAL"
fi
