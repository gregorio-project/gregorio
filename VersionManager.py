#! /usr/bin/env python2

#################################################################
# A script that eventually will manage the VERSION of gregorio.
#
# TODO: Add options to manage the version.
#
#
# Build scripts can get the VERSION with:
# VersionUpdate.py --get-current
#
#################################################################

from __future__ import print_function

import sys
import re
import argparse


version_file = '.gregorio-version'
gregorio_files = ["configure.ac",
                  "windows/gregorio-resources.rc",
                  "windows/gregorio.iss"]

gregoriotex_files = ["tex/gregoriotex.lua",
                     "plugins/gregoriotex/gregoriotex.h"]

result = []

parser = argparse.ArgumentParser(
    description='A script to manage the VERSION of gregorio.')
parser.add_argument('-c', '--get-current',
                    help='Prints the current gregorio version',
                    action='store_true')

def fetch_version(versionfile):
    with open(versionfile, 'r') as vfile:
        grever = vfile.readline()
    return grever.strip('\n')

def fileinput(infile):
    "Reads a file into a list."
    with open(infile, 'r') as source:
        filein = source.readlines()
    return filein

def replace_gregoriotex_version(infile, newver):
    "Regex to change the GREGORIO_VERSION in gregoriotex files."
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
    "Regex to change the GREGORIO_VERSION in gregorio files."
    for line in infile:
        if re.search(r'AC_INIT\(\[', line):
            result.append(re.sub(r'[\d.]+-?\w*(\],)', newver + r'\1', line))
        elif re.search(r'AppVersion', line):
            result.append(re.sub(r'[\d.]+-?\w*', newver, line))
        elif re.search(r'FileVersion', line):
            result.append(re.sub(r'[\d.]+-?\w*', newver, line))
        elif re.search(r'ProductVersion', line):
            result.append(re.sub(r'[\d.]+-?\w*', newver, line))
        else:
            result.append(line)

def writeout(filename):
    "Writes the new file contents to the file on disk."
    with open(filename, 'w') as out:
        out.write(re.sub(r'\n ', r'\n', ' '.join(result)))


def current_version(version):
    "Prints the GREGORIO_VERSION."
    print(version)

def main():
    GREGORIO_VERSION = fetch_version(version_file)
    args = parser.parse_args()
    if args.get_current:
        current_version(GREGORIO_VERSION)
        sys.exit(0)

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
