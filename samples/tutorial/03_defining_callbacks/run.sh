#!/bin/bash -e

SDIR=$(cd $(dirname $BASH_SOURCE); pwd)
SE=${SDIR}/hello_callback.py
export X10_NPLACES=${X10_NPLACES:-8}
export CARAVAN_LOG_LEVEL=${CARAVAN_LOG_LEVEL:-2}
source ${SDIR}/../common.sh

