#!/bin/bash -e

export CARAVAN_SEARCH_ENGINE_LOGLEVEL=DEBUG
HERE=$(cd $(dirname $BASH_SOURCE); pwd)
SE="python -u $HERE/bench_problem.py 4 4 0.25 4 2.0 0.5"

source ${HERE}/common.sh

