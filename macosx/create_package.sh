#!/bin/bash

HERE=`pwd`/build
cd ..
./build.sh --arch=x86_64 --enable-all-static --disable-shared --enable-static-ltdl
sudo make DESTDIR=$HERE install
./install-gtex.sh dir:$HERE
pandoc ./README.md -f markdown -t html -o $HERE/README.html
pandoc ./COPYING.md -f markdown -t html -o $HERE/COPYING.html


