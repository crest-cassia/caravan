#!/bin/bash -e

SDIR=$(cd $(dirname $BASH_SOURCE); pwd)
SE=${SDIR}/hello_serialize.py

export CARAVAN_TIMEOUT=1
source ${SDIR}/../common.sh

echo "first run is done. restarting"
SE=${SDIR}/hello_restart.py
source ${SDIR}/../common.sh
