#!/bin/bash -ex

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)

export X10_NPLACES=16
CARAVAN_DIR=$SCRIPTDIR/../..
SCHEDULER=$CARAVAN_DIR/build/a.out
export PYTHONPATH=$CARAVAN_DIR/python_module:$PYTHONPATH
export CARAVAN_SEND_RESULT_INTERVAL=0

$SCHEDULER python -u $CARAVAN_DIR/python_module/searcher/search_engine/de_optimization.py

