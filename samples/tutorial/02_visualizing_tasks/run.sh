#!/bin/bash -ex

IS_MPI=${IS_MPI:-0}
SDIR=$(cd $(dirname $BASH_SOURCE); pwd)
source ${SDIR}/../common.sh

CMD="${SCHEDULER} python ${SDIR}/hello_sleep.py"

if [ $IS_MPI = 1 ]; then
  mpiexec -n $X10_NPLACES $CMD
else
  $CMD
fi

