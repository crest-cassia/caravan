#!/bin/bash -ex

SDIR=$(cd $(dirname $BASH_SOURCE); pwd)
#SE=${SDIR}/hello_await.py
#SE=${SDIR}/hello_await_all.py
SE=${SDIR}/hello_async_await.py
source ${SDIR}/../common.sh

