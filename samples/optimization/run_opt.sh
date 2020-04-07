#!/bin/bash -e

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)

N_PROCS=8
CARAVAN_DIR=$SCRIPTDIR/../..
SCHEDULER=${CARAVAN_DIR}/caravan_scheduler/scheduler
export PYTHONPATH=$CARAVAN_DIR/caravan_search_engine:$PYTHONPATH

export CARAVAN_LOG_LEVEL=${CARAVAN_LOG_LEVEL:-1}
export CARAVAN_SEARCH_ENGINE_LOGLEVEL=${CARAVAN_SEARCH_ENGINE_LOGLEVEL:-INFO}

mpiexec -np ${N_PROCS} --oversubscribe ${SCHEDULER} python "${SCRIPTDIR}/test_de.py" 30 0.8 0.9 20

