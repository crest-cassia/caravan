#!/bin/bash -eux

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)
BUILD=${BUILD:-build}

export CARAVAN_NUM_PROC_PER_BUF=4
unset CARAVAN_TIMEOUT
export CARAVAN_SEND_RESULT_INTERVAL=2
unset CARAVAN_LOG_LEVEL

${BUILD}/a.out > stdout 2>stderr
diff stdout expected_stdout && diff stderr expected_stderr && echo OK && ${SCRIPTDIR}/clean.sh

