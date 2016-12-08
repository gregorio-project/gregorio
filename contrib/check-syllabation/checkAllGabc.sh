#!/usr/bin/env bash

PATPATH="/home/eroux/gregorio/hyphen-la/patterns/hyph_la_liturgical.dic";

DIR=${1:-'.'}

for f in $(find $DIR -name '*.gabc' | sort); do echo "analyzing $f"; python3 checkSyllabation.py -p $PATPATH $f; done