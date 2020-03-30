#!/bin/bash -e

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)
CARAVAN_DIR=$SCRIPTDIR/../../..
export PYTHONPATH=$CARAVAN_DIR/caravan_search_engine:$PYTHONPATH

python $SCRIPTDIR/hello_caravan_stub.py
# python $SCRIPTDIR/hello_ps_convergence_concurrent_stub.py
