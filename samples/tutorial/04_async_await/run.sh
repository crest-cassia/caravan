#!/bin/bash -ex

IS_MPI=${IS_MPI:-0}
SDIR=$(cd $(dirname $BASH_SOURCE); pwd)
source ${SDIR}/../common.sh

#CMD="${SCHEDULER} python ${SDIR}/hello_async_await.py"
#CMD="${SCHEDULER} python ${SDIR}/hello_await.py"
CMD="${SCHEDULER} python ${SDIR}/hello_await_all.py"

if [ $IS_MPI = 1 ]; then
  mpiexec -n $X10_NPLACES $CMD
else
  $CMD
fi

