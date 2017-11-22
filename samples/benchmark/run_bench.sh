#!/bin/bash -ex

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)

export X10_NPLACES=16
CARAVAN_DIR=$SCRIPTDIR/../..
SCHEDULER=$CARAVAN_DIR/build/a.out
export PYTHONPATH=$CARAVAN_DIR/python_module:$PYTHONPATH
export CARAVAN_SEND_RESULT_INTERVAL=0

$SCHEDULER python -u $SCRIPTDIR/bench_problem.py 10 90 0.25 4 3.0 0.8

