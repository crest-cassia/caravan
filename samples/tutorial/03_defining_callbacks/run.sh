#!/bin/bash -e

SDIR=$(cd $(dirname $BASH_SOURCE); pwd)
SE=${SDIR}/hello_callback.py
export X10_NPLACES=12
export CARAVAN_LOG_LEVEL=2
source ${SDIR}/../common.sh

