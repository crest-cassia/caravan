#!/bin/sh
#============ pjsub Options ============
#PJM --rsc-list "node=1024"
#PJM --rsc-list "elapse=01:00:00"
#PJM --rsc-list "rscgrp=large"
#PJM --mpi "proc=8192"
#PJM --stg-transfiles all
#PJM --mpi "use-rankdir"
#PJM --stgin "rank=* ../../caravan_scheduler/scheduler %r:./"
#PJM --stgin "rank=0 ./bench_problem3.py %r:./"
#PJM --stgin "rank=0 caravan_search_engine.tar %r:./"
#PJM --stgout-dir "rank=0 %r:./ %j"
#PJM --stgout "rank=0 %r:./stderr.txt.%r ./%j/"
#PJM --stgout "rank=1 %r:./stderr.txt.%r ./%j/"
#PJM -s

. /work/system/Env_base

# settings to use python
export PATH=/opt/klocal/Python-3.5.4-fujitsu/bin:${PATH}
export LD_LIBRARY_PATH=/opt/klocal/Python-3.5.4-fujitsu/lib:/opt/klocal/cblas/lib:${LD_LIBRARY_PATH}

# settings to use x10
ulimit -s 8192
export GC_MARKERS=1
export X10_NTHREADS=1
export X10RT_MPI_THREAD_SERIALIZED=1

tar xf caravan_search_engine.tar
export PYTHONPATH=caravan_search_engine:$PYTHONPATH
export CARAVAN_LOG_LEVEL=${CARAVAN_LOG_LEVEL:-1}

mpiexec -ofout-proc stdout.txt -oferr-proc stderr.txt ./scheduler python ./bench_problem3.py 819200 2 5.0 100.0

