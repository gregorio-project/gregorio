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

from distutils.util import strtobool

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
    parser.add_argument('-gt', '--git-tag',
                        help='Add a git tag with the current version',
                        action='store_true', default=False,
                        dest='git_tag')

    modify = parser.add_mutually_exclusive_group()
    modify.add_argument('--manual=',
                        help='Manually set the version.',
                        action='store',
                        dest='manual_version')
    modify.add_argument('-m', '--major',
                        help='Increment the major version: x+1.0.0-beta',
                        action='store_true', default=False,
                        dest='major')
    modify.add_argument('-e', '--enhancement',
                        help='Increment the minor version: x.y+1.0-beta',
                        action='store_true', default=False,
                        dest='minor')
    modify.add_argument('-p', '--patch',
                        help='Increment the patch version: x.y.z+1',
                        action='store_true', default=False,
                        dest='patch')
    modify.add_argument('-rc', '--release-candidate',
                        help='Change version to a -rc1, or increment -rcx+1',
                        action='store_true', default=False,
                        dest='release_candidate')
    modify.add_argument('-r', '--release',
                        help='Make a release. Removes -rcx',
                        action='store_true', default=False,
                        dest='release')
    return parser

class Version(object):
    "Class for version manipulation."

    def __init__(self, versionfile):
        self.versionfile = versionfile
        self.version = self.read_version()
        self.short_tag = None
        self.date = None

    def read_version(self):
        "Return version for instance variable"
        with open(self.versionfile, 'r') as verfile:
            self.grever = verfile.readline()
        return self.grever.strip('\n')

    def fetch_version(self):
        "Return version"
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
        print('Updating {0} with the new version: {1}\n'.format(
            self.versionfile, self.version))
        with open(self.versionfile, 'w') as verfile:
            verfile.write(self.version)
            verfile.write('\n\n*** Do not modify this file. ***\n')
            verfile.write('Use VersionManager.py to change the version.')


def replace_version(version_obj):
    "Change version in file according to heuristics."
    print('Replacing the version in the source files.\n')
    newver = version_obj.version
    for myfile in GREGORIO_FILES:
        result = []
        with open(myfile, 'r') as infile:
            for line in infile:
                if 'AC_INIT([' in line:
                    result.append(re.sub(r'[\d.]+-?\w*(\],)', newver + r'\1',
                                         line))
                elif 'AppVersion' in line:
                    result.append(re.sub(r'[\d.]+-?\w*', newver, line))
                elif 'FileVersion' in line:
                    result.append(re.sub(r'[\d.]+-?\w*', newver, line))
                elif 'ProductVersion' in line:
                    result.append(re.sub(r'[\d.]+-?\w*', newver, line))
                elif 'GREGORIO_VERSION' in line:
                    result.append(re.sub(r'\"[\d.]+-?\w*\"$', '\"' + newver
                                         + '\"', line))
                elif 'internalversion =' in line:
                    result.append(re.sub(r'\'[\d.]+-?\w*\'$', '\'' + newver
                                         + '\'', line))
                else:
                    result.append(line)
        with open(myfile, 'w') as outfile:
            outfile.write(''.join(result))

def confirm_replace(oldver, newver):
    "Query the user to confirm action"
    query = 'Update version from {0} --> {1} [y/n]?'.format(oldver, newver)
    print(query)
    consent = strtobool(raw_input().lower())
    if not consent:
        print('Aborting.')
        sys.exit(1)

def release_candidate(version_obj):
    "Changes x.y.z-beta to x.y.z-rc1 OR increments x.y.z-rcx+1"
    oldversion = version_obj.version
    if '-rc' in oldversion:
        newversion = re.sub(r'\d+$', lambda x: str(int(x.group()) +1),
                            oldversion)
    elif '-' in oldversion:
        newversion = re.sub(r'-.*', '-rc1', oldversion)
    confirm_replace(oldversion, newversion)
    version_obj.update_version(newversion)
    replace_version(version_obj)

def bump_major(version_obj):
    "Changed the major version number: x.y.z --> x+1.0.0-beta"
    oldversion = version_obj.version
    nums = re.search(r'(\d+)(\.\d+)(\.\d+)', oldversion)
    newversion = str(int(nums.group(1)) +1) + '.0.0-beta'
    confirm_replace(oldversion, newversion)
    version_obj.update_version(newversion)
    replace_version(version_obj)

def bump_minor(version_obj):
    "Changed the minor version number: x.y.z --> x.y+1.0-beta"
    oldversion = version_obj.version
    nums = re.search(r'(\d+\.)(\d+)(\.\d+)', oldversion)
    newversion = nums.group(1) + str(int(nums.group(2)) +1) + '.0-beta'
    confirm_replace(oldversion, newversion)
    version_obj.update_version(newversion)
    replace_version(version_obj)

def bump_patch(version_obj):
    "Changed the patch version number: x.y.z --> x.y.z+1"
    oldversion = version_obj.version
    nums = re.search(r'(\d+\.\d+\.)(\d+)', oldversion)
    newversion = nums.group(1) + str(int(nums.group(2)) +1)
    confirm_replace(oldversion, newversion)
    version_obj.update_version(newversion)
    replace_version(version_obj)

def set_manual_version(version_obj, user_version):
    "Changed the version number to a user supplied value"
    oldversion = version_obj.version
    if not re.match(r'[\d.]{5,}-?\w*$', user_version):
        print('Bad version string. Use this style: x.y.z or x.y.z-beta')
        sys.exit(1)
    newversion = user_version
    confirm_replace(oldversion, newversion)
    version_obj.update_version(newversion)
    replace_version(version_obj)

def main():
    "Main function"
    parser = get_parser()
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(1)
    args = parser.parse_args()
    gregorio_version = Version(VERSION_FILE)
    if args.get_current:
        gregorio_version.fetch_version()
    elif args.get_debian_stable:
        gregorio_version.fetch_version_debian_stable()
    elif args.get_debian_git:
        gregorio_version.fetch_version_debian_git()
    elif args.major:
        bump_major(gregorio_version)
    elif args.minor:
        bump_minor(gregorio_version)
    elif args.patch:
        bump_patch(gregorio_version)
    elif args.release_candidate:
        release_candidate(gregorio_version)
    elif args.release:
        pass
    elif args.manual_version:
        print(args.manual_version)
        set_manual_version(gregorio_version, args.manual_version)

if __name__ == "__main__":
    main()
