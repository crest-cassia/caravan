#!/bin/bash -e

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)

N_PROCS=${N_PROCS:-8}
CARAVAN_DIR=$SCRIPTDIR/../..
SCHEDULER=$CARAVAN_DIR/caravan_scheduler/scheduler
export PYTHONPATH=$CARAVAN_DIR/caravan_search_engine:$PYTHONPATH
export CARAVAN_LOG_LEVEL=${CARAVAN_LOG_LEVEL:-1}
#export CARAVAN_TIMEOUT=20

mpiexec ${MPIEXEC_OPT} -n $N_PROCS $SCHEDULER python3 "$SCRIPTDIR/main.py" $1

