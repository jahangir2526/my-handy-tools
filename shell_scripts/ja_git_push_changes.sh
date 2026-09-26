#!/usr/bin/env bash
# Author: S M Jahangir Alam <jahangir2526@gmail.com>
# Last updated: 2026-08-29 13:26:57 +08
# Push code changes to the remote repository.
if [ -z "$1" ]
then
	echo "Commit message is empty";
	echo "Example: $0 \"Describe the changes\" \"feature/my-branch\"";
	exit;
fi

if [ -z "$2" ]
then
	echo "Branch name is empty";
	echo "Example: $0 \"Describe the changes\" \"feature/my-branch\"";
	exit;
fi

branch_name="$2"

if [ "$branch_name" = "main" ]
then
	confirmation=$(osascript -e 'display dialog "This will update the main branch. Do you want to continue?" buttons {"No", "Yes"} default button "No" with icon caution' 2>/dev/null)
	if [ "$confirmation" != "button returned:Yes" ]
	then
		echo "Push to main cancelled.";
		exit;
	fi
fi

git add .
git commit -m "$1"
git pull origin "$branch_name" && git push origin "$branch_name"
