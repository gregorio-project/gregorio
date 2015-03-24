#! /usr/bin/env python2

"""
    A script that eventually will manage the VERSION of gregorio.

    See VersionUpdate.py -h for help
"""

from __future__ import print_function

import sys
import re
import argparse
import subprocess
import time

VERSION_FILE = '.gregorio-version'
GREGORIO_FILES = ["configure.ac",
#                  "windows/gregorio-resources.rc",
#                  "windows/gregorio.iss",
#                  "tex/gregoriotex.lua",
#                  "plugins/gregoriotex/gregoriotex.h"
                 ]

def get_parser():
    "Return command line parser"
    parser = argparse.ArgumentParser(
        description='A script to manage the VERSION of gregorio.')
    parser.add_argument('-c', '--get-current',
                        help='Prints the current gregorio version',
                        action='store_true')
    parser.add_argument('-d', '--get-debian-stable',
                        help='Prints the version for Debian stable package',
                        action='store_true')
    parser.add_argument('-dg', '--get-debian-git',
                        help='Prints the version for Debian git package',
                        action='store_true')
    return parser

def fetch_version(versionfile):
    "Return version"
    with open(versionfile, 'r') as vfile:
        grever = vfile.readline()
    return grever.strip('\n')

def fetch_version_debian_stable(versionfile):
    "Return version for Debian stable package"
    with open(versionfile, 'r') as vfile:
        grever = vfile.readline()
    return grever.strip('\n').replace('-', '~')

def fetch_version_debian_git(versionfile):
    "Return version for Debian git package"
    main_version = fetch_version_debian_stable(versionfile)
    short_tag = subprocess.check_output(['git', 'rev-parse', '--short', 'HEAD'])
    short_tag = short_tag.strip('\n')
    date = time.strftime("%Y%m%d")
    return "%s+git%s+%s" % (main_version, date, short_tag)

def replace_version(infilename, newver):
    "Change version in file according to heuristics."
    result = []
    with open(infilename, 'r') as infile:
        for line in infile:
            if 'AC_INIT([' in line:
                result.append(re.sub(r'[\d.]+-?\w*(\],)', newver + r'\1', line))
            elif 'AppVersion' in line:
                result.append(re.sub(r'[\d.]+-?\w*', newver, line))
            elif 'FileVersion' in line:
                result.append(re.sub(r'[\d.]+-?\w*', newver, line))
            elif 'ProductVersion' in line:
                result.append(re.sub(r'[\d.]+-?\w*', newver, line))
            elif 'GREGORIO_VERSION' in line:
                result.append(re.sub(r'\"[\d.]+-?\w*\"$', '\"' + newver + '\"',
                                     line))
            elif 'internalversion =' in line:
                result.append(re.sub(r'\'[\d.]+-?\w*\'$', '\'' + newver + '\'',
                                     line))
            else:
                result.append(line)
    with open(infilename, 'w') as outfile:
        outfile.write(''.join(result))

def main():
    "Main function"
    parser = get_parser()
    args = parser.parse_args()
    if args.get_current:
        gregorio_version = fetch_version(VERSION_FILE)
        print(gregorio_version)
        sys.exit(0)
    elif args.get_debian_stable:
        gregorio_version = fetch_version_debian_stable(VERSION_FILE)
        print(gregorio_version)
        sys.exit(0)
    elif args.get_debian_git:
        gregorio_version = fetch_version_debian_git(VERSION_FILE)
        print(gregorio_version)
        sys.exit(0)
    gregorio_version = fetch_version(VERSION_FILE)
    for myfile in GREGORIO_FILES:
        replace_version(myfile, gregorio_version)

if __name__ == "__main__":
    main()
