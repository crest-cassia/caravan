#!/bin/bash -e

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)
CARAVAN_DIR=${SCRIPTDIR}/../..

export MPI_PROCS=${MPI_PROCS:-8}
SCHEDULER="${CARAVAN_DIR}/caravan_scheduler/scheduler"
export PYTHONPATH=$CARAVAN_DIR/caravan_search_engine:$PYTHONPATH
export CARAVAN_SEARCH_ENGINE_LOGLEVEL=${CARAVAN_SEARCH_ENGINE_LOGLEVEL:-INFO}
export CARAVAN_LOG_LEVEL=${CARAVAN_LOG_LEVEL:-1}

mpiexec --oversubscribe -n ${MPI_PROCS} "${SCHEDULER}" python ${SE}

