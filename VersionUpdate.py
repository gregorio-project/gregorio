#! /usr/bin/env python2

#################################################################
# A script that inserts the VERSION into the source code files.
#
# GREGORIO_VERSION is the version of gregorio.
#
# To update the version: Modify the GREGORIO_VERSION.
#                        Save this file.
#                        $ python2 VersionUpdate.py
#
# Build scripts can extract the VERSION with:
# grep -oE '[0-9]+\.[0-9]+\.[0-9]+-?[[:alnum:]]*' VersionUpdate.py
#
#################################################################

import re


GREGORIO_VERSION = '3.0.0-beta'

gregorio_files = ["configure.ac",
                  "windows/gregorio-resources.rc",
                  "windows/gregorio.iss"]

gregoriotex_files = ["tex/gregoriotex.lua",
                     "plugins/gregoriotex/gregoriotex.h"]

result = []


def fileinput(infile):
    with open(infile, 'r') as source:
        filein = source.readlines()
    return filein

def replace_gregoriotex_version(infile, newver):
    for line in infile:
        if re.search(r'internalversion =', line):
            result.append(re.sub(r'\'[\d.]+-?\w*\'$', '\'' + newver + '\'',
                                 line))
        elif re.search(r'GREGORIO_VERSION', line):
            result.append(re.sub(r'\"[\d.]+-?\w*\"$', '\"' + newver + '\"',
                                 line))
        else:
            result.append(line)

def replace_gregorio_version(infile, newver):
    for line in infile:
        if re.search(r'AC_INIT\(\[', line):
            result.append(re.sub
                          (r'[\d.]+-?\w*(\],)', newver + r'\1', line))
        elif re.search(r'AppVersion', line):
            result.append(re.sub(r'[\d.]+-?\w*', newver, line))
        elif re.search(r'FileVersion', line):
            result.append(re.sub(r'[\d.]+-?\w*', newver, line))
        elif re.search(r'ProductVersion', line):
            result.append(re.sub(r'[\d.]+-?\w*', newver, line))
        else:
            result.append(line)

def writeout(filename):
    with open(filename, 'w') as out:
        out.write(re.sub(r'\n ', r'\n', ' '.join(result)))
            
def main():
    global result
    for f in gregoriotex_files:
        src = fileinput(f)
        replace_gregoriotex_version(src, GREGORIO_VERSION)
        writeout(f)
        result = []
    for f in gregorio_files:
        src = fileinput(f)
        replace_gregorio_version(src, GREGORIO_VERSION)
        writeout(f)
        result = []

if __name__ == "__main__":
    main()
