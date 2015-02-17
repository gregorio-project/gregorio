#! /usr/bin/env python2

# A script that inserts the Gregorio Version into the the necessary files.

import re


version_file = 'VERSION'
files_to_change = ["tex/gregoriotex.lua", "plugins/gregoriotex/gregoriotex.h"]
result = []
VERSION = ''

def get_version(infile):
    with open(infile, 'r') as vfile:
        ver = vfile.read()
    return ver.strip('\n')


def fileinput(infile):
    with open(infile, 'r') as source:
        filein = source.readlines()
    return filein


def replace(infile, ver):
    for line in infile:
        if re.search(r'internalversion =', line):
            result.append(re.sub(r'[0-9.]+$', ver, line))
        elif re.search(r'GREGORIOTEX_API_VERSION', line):
            result.append(re.sub(r'[0-9.]+$', ver, line))
        else:
            result.append(line)

def writeout(filename):
    with open(filename, 'w') as out:
        out.write(re.sub(r'\n ', r'\n', ' '.join(result)))
            
def main():
    VERSION = get_version(version_file)
    for i in files_to_change:
        global result
        result = []
        src = fileinput(i)
        replace(src, VERSION)
        writeout(i)

if __name__ == "__main__":
    main()
