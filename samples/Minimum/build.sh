#!/bin/bash -eux

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)
BUILD=`pwd`/build
mkdir -p ${BUILD}
cd ${SCRIPTDIR}/simulator
make
cp libmain.a ${BUILD}
cd -
x10c++ -v -O -sourcepath ${SCRIPTDIR}/../..:${SCRIPTDIR} -d ${BUILD} ${SCRIPTDIR}/MyMain.x10 -VERBOSE_CHECKS -cxx-postarg libmain.a

