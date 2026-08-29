#!/bin/bash

# parse command line options
while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -u|--url)
    target_url="$2"
    shift # past argument
    ;;
    *)
        # unknown option
    ;;
esac
shift # past argument or value
done

format="----------------------------
    time_namelookup:  %{time_namelookup}
       time_connect:  %{time_connect}
    time_appconnect:  %{time_appconnect}
   time_pretransfer:  %{time_pretransfer}
      time_redirect:  %{time_redirect}
 time_starttransfer:  %{time_starttransfer}
----------------------------
         time_total:  %{time_total}\n"

if [ "$target_url" ]; then
  echo "Sending GET request to $target_url"
  curl -w "$format" -o /dev/null -s "$target_url"
else
  echo "Target URL not specified."
fi
