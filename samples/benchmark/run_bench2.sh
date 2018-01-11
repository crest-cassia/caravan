#!/bin/bash -ex

IS_MPI=${IS_MPI:-0}

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)

export X10_NPLACES=${X10_NPLACES:-16}
CARAVAN_DIR=$SCRIPTDIR/../..
SCHEDULER=$CARAVAN_DIR/caravan_scheduler/scheduler
export PYTHONPATH=$CARAVAN_DIR/python_module:$PYTHONPATH
export CARAVAN_SEND_RESULT_INTERVAL=0
export CARAVAN_LOG_LEVEL=${CARAVAN_LOG_LEVEL:-2}

CMD=$SCHEDULER python -u $SCRIPTDIR/bench2.py 40 20 5 20 1.0 0.8

if [ $IS_MPI = 1 ]; then
  mpiexec -n $X10_NPLACES $CMD
else
  $CMD
fi

