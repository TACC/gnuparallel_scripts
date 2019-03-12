#!/bin/bash

if [ $# -ne 1 ] ; then
  echo "Usage: $0 commandlines"
  exit 1
fi

ncommands=`cat $1 | wc -l`
parallel gnuparallel_command_execute.sh "$1" ::: `seq 1 $ncommands`
