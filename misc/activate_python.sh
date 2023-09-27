#!/bin/bash
# request comput node for interactive session
# to run python or debugging
# max hours - 8 (?)
# start conda and activate session
cndn="anls"

salloc --x11=first -q batch -t 8:00:00 --nodes=1 -A marine-cpu
wait

if $? == 0; then 
  eval "$($PYPATH/bin/conda shell.bash hook)"
  conda activate $cndn
  exit 0
else
  echo "Could not get compute node"
  exit 1
fi

