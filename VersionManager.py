#! /usr/bin/env python2

#################################################################
# A script that eventually will manage the VERSION of gregorio.
#
# See VersionUpdate.py -h for help
#
#################################################################

from __future__ import print_function

import sys
import re
import argparse
import subprocess
import time

VERSION_FILE = '.gregorio-version'
GREGORIO_FILES = ["configure.ac",
                  "windows/gregorio-resources.rc",
                  "windows/gregorio.iss"]

GREGORIOTEX_FILES = ["tex/gregoriotex.lua",
                     "plugins/gregoriotex/gregoriotex.h"]

result = []

def get_parser():
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
    return parser

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
    short_tag = subprocess.check_output(['git', 'rev-parse', '--short', 'HEAD'])
    short_tag = short_tag.strip('\n')
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
    gregorio_version = None
    parser = get_parser()
    args = parser.parse_args()
    if args.get_current:
        gregorio_version = fetch_version(VERSION_FILE)
        current_version(gregorio_version)
        sys.exit(0)
    elif args.get_debian_main:
        gregorio_version_debian = fetch_version_debian(VERSION_FILE)
        current_version(gregorio_version_debian)
        sys.exit(0)
    elif args.get_debian_git:
        gregorio_version_debian_git = fetch_version_debian_git(VERSION_FILE)
        current_version(gregorio_version_debian_git)
        sys.exit(0)

    global result
    gregorio_version = fetch_version(VERSION_FILE)
    for myfile in GREGORIOTEX_FILES:
        src = fileinput(myfile)
        replace_gregoriotex_version(src, gregorio_version)
        writeout(myfile)
        result = []
    for myfile in GREGORIO_FILES:
        src = fileinput(myfile)
        replace_gregorio_version(src, gregorio_version)
        writeout(myfile)
        result = []

if __name__ == "__main__":
    main()
