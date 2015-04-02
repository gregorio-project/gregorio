#!/bin/bash

# Test to see if we have a valid TeX installation

kpsewhich -var-value TEXMFLOCAL

exit $?
