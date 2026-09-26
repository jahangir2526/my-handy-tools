#!/usr/bin/env bash
# Author: S M Jahangir Alam <jahangir2526@gmail.com>
# Last updated: 2026-09-26
# Get absoulate path of a file
if [ -z "$1" ]
then
	echo "File name is empty";
	exit;
fi

echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"