#!/bin/bash -eux

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)
BUILD=`pwd`/build
mkdir -p ${BUILD}
cd ${SCRIPTDIR}/caravan/simulator
make
cp main.a ${BUILD}
cp main.hpp ${SCRIPTDIR}/caravan
cd -
x10c++ -sourcepath ${SCRIPTDIR}/../..:${SCRIPTDIR} -d ${BUILD} ${SCRIPTDIR}/MyMain.x10 -VERBOSE_CHECKS -cxx-postarg libmain.a

