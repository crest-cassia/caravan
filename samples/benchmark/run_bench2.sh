#!/bin/bash -e

export CARAVAN_SEARCH_ENGINE_LOGLEVEL=DEBUG
HERE=$(cd $(dirname $BASH_SOURCE); pwd)
SE="python -u $HERE/bench_problem2.py 10 0 4 10 1.0 0.8"

source ${HERE}/common.sh

