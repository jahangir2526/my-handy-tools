#!/usr/bin/env bash
# Author: S M Jahangir Alam <jahangir2526@gmail.com>
# Last updated: 2026-08-29 13:26:57 +08
# ./<name>.sh "<string1>" "<string2>"

VAR1="$1"
VAR2="$2"

if [ "$VAR1" = "$VAR2" ]; then
    echo "EQUAL"
else
    echo "NOT EQUAL"
fi
