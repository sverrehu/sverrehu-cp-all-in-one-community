#!/bin/bash

if test \! -x ./generate.sh
then
  echo "must be run from the ssl directory"
  exit 1
fi

rm -f *~ *.p12 *.crt *.key *.properties password.txt
