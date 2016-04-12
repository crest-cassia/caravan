#!/bin/bash -eux

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE); pwd)
BUILD=`pwd`/build
mkdir -p ${BUILD}
cd ${SCRIPTDIR}/caravan/cpp
make
cp libising2d.a ${BUILD}
cd -
x10c++ -sourcepath ${SCRIPTDIR}/../..:${SCRIPTDIR} -d ${BUILD} ${SCRIPTDIR}/IsingSearch.x10 -VERBOSE_CHECKS -cxx-postarg libising2d.a
