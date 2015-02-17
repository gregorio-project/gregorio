#! /usr/bin/env python2

#################################################################
# A script that inserts the Version into the the necessary files.
#
# GREGORIOTEX_API_VERSION is the version of gregoriotex.
# GREGORIO_VERSION is the version of gregorio.
#################################################################

import re


version_file = 'VERSION'
gregoriotex_api_files = ["tex/gregoriotex.lua",
                       "plugins/gregoriotex/gregoriotex.h"]
gregorio_files = []
result = []
GREGORIOTEX_API_VERSION = ''
GREGORIO_VERSION = ''

def get_version(versionfile):
    with open(versionfile, 'r') as vfile:
        ver = vfile.readlines()
    return (ver[0].split(' = ')[1], ver[1].split(' = ')[1])

def fileinput(infile):
    with open(infile, 'r') as source:
        filein = source.readlines()
    return filein

def replace(infile, newver):
    for line in infile:
        if re.search(r'internalversion =', line):
            result.append(re.sub(r'[0-9.]+$', newver, line))
        elif re.search(r'GREGORIOTEX_API_VERSION', line):
            result.append(re.sub(r'[0-9.]+$', newver, line))
        else:
            result.append(line)

def writeout(filename):
    with open(filename, 'w') as out:
        out.write(re.sub(r'\n ', r'\n', ' '.join(result)))
            
def main():
    global GREGORIOTEX_API_VERSION
    global GREGORIO_VERSION
    GREGORIOTEX_API_VERSION, GREGORIO_VERSION = get_version(version_file)
    for i in gregoriotex_api_files:
        global result
        result = []
        src = fileinput(i)
        replace(src, GREGORIOTEX_API_VERSION)
        writeout(i)

if __name__ == "__main__":
    main()
