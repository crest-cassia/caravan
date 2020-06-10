#!/bin/bash
set -eux

mpiFCCpx -Nclang -Ijson/include -I$HOME/local/include -std=c++11 -DUSE_BOOST_FS -o scheduler -Kfast main.cpp ~/local/lib/libboost_filesystem.a ~/local/lib/libboost_system.a
