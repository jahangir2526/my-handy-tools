#!/bin/bash
echo "\$0: $0 #shows the script name";
echo "\${PWD}/\$0: ${PWD}/$0 #shows the absoulate path of script"
echo "\$1: $1 #first command line argument";
echo "\$2: $2 #second command line argument";
echo "\$3: $3 #third command line argument";
echo "\$*: $* #all command line arguments";
echo "\$?: $? #status of previous command";
