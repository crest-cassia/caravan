#!/bin/bash -e

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)

N_PROCS=8
CARAVAN_DIR=$SCRIPTDIR/../..
SCHEDULER=${CARAVAN_DIR}/caravan_scheduler/scheduler
export PYTHONPATH="${CARAVAN_DIR}/caravan_search_engine":$PYTHONPATH

export CARAVAN_LOG_LEVEL=${CARAVAN_LOG_LEVEL:-1}
export CARAVAN_SEARCH_ENGINE_LOGLEVEL=${CARAVAN_SEARCH_ENGINE_LOGLEVEL:-INFO}

mpiexec ${MPIEXEC_OPT} -n ${N_PROCS} "${SCHEDULER}" python3 "${SCRIPTDIR}/nsga2.py" 200 40 0.9 1234

python3 "${SCRIPTDIR}/make_plot.py"

