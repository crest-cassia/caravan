#!/bin/bash -e

set -x

export CARAVAN_SEARCH_ENGINE_LOGLEVEL=DEBUG
HERE=$(cd $(dirname $BASH_SOURCE); pwd)
SE="python3 $HERE/bench_problem.py 2 1 0.25 4 2.0 0.5"

source ${HERE}/common.sh
