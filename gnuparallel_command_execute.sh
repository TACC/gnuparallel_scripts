#!/bin/bash

if [ $# -ne 2 ] ; then
  echo "Usage: $0 commandlines number"
  exit 1
fi

#set -x
sed -n -e "$2p" "$1" | /bin/bash -
