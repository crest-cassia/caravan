#!/bin/bash -e

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)

export N_PROCS=8
CARAVAN_DIR=$SCRIPTDIR/../..
SCHEDULER=${HOME}/sandbox/caravan_cpp/cmake-build-debug/caravan_scheduler
export PYTHONPATH=$CARAVAN_DIR/caravan_search_engine:$PYTHONPATH

export CARAVAN_SEND_RESULT_INTERVAL=${CARAVAN_SEND_RESULT_INTERVAL:-0}
export export CARAVAN_SEARCH_ENGINE_LOGLEVEL=${CARAVAN_SEARCH_ENGINE_LOGLEVEL:-INFO}
export CARAVAN_LOG_LEVEL=${CARAVAN_LOG_LEVEL:-1}

CMD="${SCHEDULER} ${SE}"
mpiexec -np ${N_PROCS} --oversubscribe ${CMD}

