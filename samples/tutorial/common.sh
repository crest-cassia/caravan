#!/bin/bash -ex

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)

export X10_NPLACES=${X10_NPLACES:-16}
CARAVAN_DIR=$SCRIPTDIR/../..
SCHEDULER=$CARAVAN_DIR/caravan_scheduler/scheduler
export PYTHONPATH=$CARAVAN_DIR/caravan_search_engine:$PYTHONPATH
export CARAVAN_SEND_RESULT_INTERVAL=0
export CARAVAN_LOG_LEVEL=${CARAVAN_LOG_LEVEL:-2}

