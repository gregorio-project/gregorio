#!/bin/bash

../build.sh --arch=x86_64 --enable-all-static --disable-shared --enable-static-ltdl
HERE=`pwd`
sudo make DESTDIR=$HERE install
../install-gtex.sh dir:

