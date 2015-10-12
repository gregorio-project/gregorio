#!/bin/bash

# Test to see if we have a valid TeX installation

TEXMFLOCAL=`kpsewhich -var-value TEXMFLOCAL`
if [ -n "$TEXMFLOCAL" ]; then
    echo "Passed"
    exit 0
else
    TEXMFLOCAL=`/usr/texbin/kpsewhich -var-value TEXMFLOCAL`
    if [ -n "$TEXMFLOCAL" ]; then
        echo "Passed"
        exit 0
    else
        TEMFLOCAL=`/Library/TeX/texbin/kpsewhich -var-value TEXMFLOCAL`
        if [-n "$TEXMFLOCAL" ]; then
            echo "Passed"
            exit 0
        else
            echo "Failed"
            exit 1
        fi
    fi
fi
