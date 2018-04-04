#!/bin/bash -e

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)

export X10_NPLACES=${X10_NPLACES:-8}
CARAVAN_DIR=$SCRIPTDIR/../..
SCHEDULER=$CARAVAN_DIR/caravan_scheduler/scheduler
export PYTHONPATH=$CARAVAN_DIR/caravan_search_engine:$PYTHONPATH
export CARAVAN_SEND_RESULT_INTERVAL=${CARAVAN_SEND_RESULT_INTERVAL:-0}
export export CARAVAN_SEARCH_ENGINE_LOGLEVEL=${CARAVAN_SEARCH_ENGINE_LOGLEVEL:-INFO}
export CARAVAN_LOG_LEVEL=${CARAVAN_LOG_LEVEL:-1}

CMD="${SCHEDULER} python ${SE}"

IS_MPI=${IS_MPI:-0}
if [ $IS_MPI = 1 ]; then
  mpiexec -n $X10_NPLACES $CMD
else
  $CMD
fi

