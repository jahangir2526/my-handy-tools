#!/usr/bin/env bash
# Author: S M Jahangir Alam <jahangir2526@gmail.com>
# Last updated: 2026-08-29 13:26:57 +08
# Push code changes to the remote repository.
if [ -z "$1" ]
then
	echo "Commit message is empty";
	exit;
fi

git add .
git commit -m "$1"
git pull && git push origin main 
