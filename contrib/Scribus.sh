#!/bin/sh

export PATH=$PATH:/Library/TeX/texbin:/usr/local/bin

logger "`dirname \"$0\"`/Scribus"

exec "`dirname \"$0\"`/Scribus" $@
