#!/bin/bash -e

SDIR=$(cd $(dirname $BASH_SOURCE); pwd)
SE=${SDIR}/hello_serialize.py
source ${SDIR}/../common.sh

echo "dump is finished."
echo 'calling `load` method'
python ${SDIR}/hello_load.py

