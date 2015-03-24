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
import subprocess
import time

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
parser.add_argument('-d', '--get-debian-main',
                    help='Prints the version converted for Debian package',
                    action='store_true')
parser.add_argument('-dg', '--get-debian-git',
                    help='Prints the version converted for Debian git package',
                    action='store_true')

def fetch_version(versionfile):
    with open(versionfile, 'r') as vfile:
        grever = vfile.readline()
    return grever.strip('\n')

def fetch_version_debian(versionfile):
    with open(versionfile, 'r') as vfile:
        grever = vfile.readline()
    return grever.strip('\n').replace('-', '~')

def fetch_version_debian_git(versionfile):
    main_version = fetch_version_debian(versionfile)
    short_tag = subprocess.check_output(['git', 'rev-parse', '--short', 'HEAD']).strip('\n')
    #short_tag = git_process.strip('\n')
    date = time.strftime("%Y%m%d")
    return "%s+git%s+%s" % (main_version, date, short_tag)

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
    GREGORIO_VERSION = None
    args = parser.parse_args()
    if args.get_current:
        GREGORIO_VERSION = fetch_version(version_file)
        current_version(GREGORIO_VERSION)
        sys.exit(0)
    elif args.get_debian_main:
        GREGORIO_VERSION_DEBIAN = fetch_version_debian(version_file)
        current_version(GREGORIO_VERSION_DEBIAN)
        sys.exit(0)
    elif args.get_debian_git:
        GREGORIO_VERSION_DEBIAN_GIT = fetch_version_debian_git(version_file)
        current_version(GREGORIO_VERSION_DEBIAN_GIT)
        sys.exit(0)

    global result
    GREGORIO_VERSION = fetch_version(version_file)
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
