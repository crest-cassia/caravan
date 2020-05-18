#!/bin/bash -e

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)

CARAVAN_DIR=$SCRIPTDIR/../..
export PYTHONPATH="${CARAVAN_DIR}/caravan_search_engine":$PYTHONPATH
python3 "${SCRIPTDIR}/analyze.py" tasks.pickle

