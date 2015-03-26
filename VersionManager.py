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
                  "windows/gregorio-resources.rc",
                  "windows/gregorio.iss",
                  "tex/gregoriotex.lua",
                  "plugins/gregoriotex/gregoriotex.h"
                 ]

def get_parser():
    "Return command line parser"
    parser = argparse.ArgumentParser(
        description='A script to manage the VERSION of gregorio.')
    parser.add_argument('-c', '--get-current',
                        help='Prints the current gregorio version',
                        action='store_true', default=False)
    parser.add_argument('-d', '--get-debian-stable',
                        help='Prints the version for Debian stable package',
                        action='store_true', default=False)
    parser.add_argument('-dg', '--get-debian-git',
                        help='Prints the version for Debian git package',
                        action='store_true', default=False)
    parser.add_argument('-gc', '--git-commit',
                        help='Commit the version change',
                        action='store_true', default=False)
    parser.add_argument('-gt', '--git-tag',
                        help='Commit the version change and add a git tag',
                        action='store_true', default=False)
    
    modversion = parser.add_mutually_exclusive_group()
    modversion.add_argument('-m', '--major',
                            help='Increment the major version',
                            action='store_true', default=False,
                            dest='major')
    modversion.add_argument('-e', '--enhancement',
                            help='Increment the minor version',
                            action='store_true', default=False,
                            dest='minor')
    modversion.add_argument('-b', '--bugfix',
                            help='Increment the patch version',
                            action='store_true', default=False,
                            dest='patch')
    modversion.add_argument('--manual=',
                            help='Manually set the version.',
                            action='store',
                            dest='manual_version')
    return parser

class Version(object):
    "Class for version manipulation."


    def __init__(self, versionfile, xyz):
        self.versionfile = versionfile
        self.major, self.minor, self.patch = xyz
        self.version = self.read_version(self.versionfile)

    def read_version(self, versionfile):
        "Return version"
        with open(versionfile, 'r') as vfile:
            self.grever = vfile.readline()
        return self.grever.strip('\n')

    def fetch_version(self):
        print(self.version)
        sys.exit(0)

    def fetch_version_debian_stable(self):
        "Return version for Debian stable package"
        print(self.version.replace('-', '~'))
        sys.exit(0)

    def fetch_version_debian_git(self):
        "Return version for Debian git package"
        self.short_tag = subprocess.check_output(
            ['git', 'rev-parse', '--short', 'HEAD'])
        self.short_tag = self.short_tag.strip('\n')
        self.date = time.strftime("%Y%m%d")
        print("{0}+git{1}+{2}".format(self.version.replace('-', '~'),
                                self.date, self.short_tag))
        sys.exit(0)

    def update_version(self, newversion):
        "Update self.version and .gregorio-version with the new version."
        self.version = newversion
        with open(self.versionfile, 'w') as verfile:
            verfile.write(self.version)
            verfile.write('\n*** Do not modify this file. ***\n')
            verfile.write('Use VersionManager.py to change the version.')


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
    if len(sys.argv)==1:
        parser.print_help()
        sys.exit(1)
    args = parser.parse_args()
    gregorio_version = Version(VERSION_FILE,
                               (args.major, args.minor, args.patch))
    if args.get_current:
        gregorio_version.fetch_version()
    elif args.get_debian_stable:
        gregorio_version.fetch_version_debian_stable()
    elif args.get_debian_git:
        gregorio_version.fetch_version_debian_git()

    elif args.major or args.minor or args.patch:
        print('rstrstr')
        print(gregorio_version.version)

    elif args.manual_version:
        print(args.manual_version)
        if not re.match(r'[\d.]{5,}-?\w*$', args.manual_version):
            print('Bad version string. Use this style: x.y.z or x.y.z-beta')
        new_version = args.manual_version
        gregorio_version.update_version(new_version)

    # for myfile in GREGORIO_FILES:
    #     replace_version(myfile, gregorio_version.version)

if __name__ == "__main__":
    main()
