#!/bin/bash -ex

SDIR=$(cd $(dirname $BASH_SOURCE); pwd)
SE=${SDIR}/hello_ps_convergence_concurrent.py
#SE=${SDIR}/hello_ps_convergence.py
#SE=${SDIR}/hello_ps.py
source ${SDIR}/../common.sh

