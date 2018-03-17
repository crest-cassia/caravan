#!/bin/bash -ex

IS_MPI=${IS_MPI:-0}

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)

export X10_NPLACES=${X10_NPLACES:-16}
CARAVAN_DIR=$SCRIPTDIR/../..
SCHEDULER=$CARAVAN_DIR/caravan_scheduler/scheduler
export PYTHONPATH=$CARAVAN_DIR/python_module:$PYTHONPATH
export CARAVAN_SEND_RESULT_INTERVAL=0
export CARAVAN_TIMEOUT=10
export CARAVAN_LOG_LEVEL=${CARAVAN_LOG_LEVEL:-2}

CMD="$SCHEDULER python $SCRIPTDIR/bench_problem.py 10 90 0.25 4 3.0 0.8 table.pickle"

if [ $IS_MPI = 1 ]; then
  mpiexec -n $X10_NPLACES $CMD
else
  $CMD
fi

