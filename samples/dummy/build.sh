#!/bin/bash -eux

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)
BUILD=`pwd`/build
mkdir -p ${BUILD}

x10c++ -v -O -sourcepath ${SCRIPTDIR}/../..:${SCRIPTDIR} -d ${BUILD} ${SCRIPTDIR}/Dummy.x10 -VERBOSE_CHECKS

