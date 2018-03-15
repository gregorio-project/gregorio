# !/usr/bin/env bash

# Copyright (C) 2016-2018 The Gregorio Project (see CONTRIBUTORS.md)
#
# This file is part of Gregorio.
#
# Gregorio is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Gregorio is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Gregorio.  If not, see <http://www.gnu.org/licenses/>.

######################################################################
# This script uploads the current release to ctan

if [[ "$1" =~ ^--?(h|\?|help)$ ]]; then
  echo "Usage: $0 \"<release message>\" \"<optional message to upload managers>\""
  exit 0
fi

announce="$1"
note="$2"
if [ -z "$1" ]; then
  echo "No announcement text"
  read -r -p "Are you sure you want to continue? [y/N] " response
  if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
     exit 1
  fi
fi

if [[ ! -e "gregoriotex.ctan.zip" ]]; then
  echo "CTAN release not created"
  echo "Please run \"make ctan\" and try again"
  exit 1
fi

VERSION=`./VersionManager.py --get-current`
FILE_VERSION=`echo $VERSION | sed s:[.]:_:g`
pkgfile="gregorio-$FILE_VERSION.pkg"

# copy config file
cp "ctan-o-mat.config" "gregorio-$FILE_VERSION.pkg"

# changelog entry
changes=$(awk "/$VERSION/ {p=1; next}; /[0-9]+\.[0-9]+\.[0-9]+/ {p=0}; p" "CHANGELOG.md")
perl -s -i -0777 -pe 's/<<<CHANGELOG>>>/$to/' -- -to="$changes" "$pkgfile"

# Release message
perl -s -i -0777 -pe 's/<<<ANNOUNCEMENT>>>/$to/' -- -to="$announce" "$pkgfile"

# optional message to upload managers
perl -s -i -0777 -pe 's/<<<NOTE>>>/$to/' -- -to="$note" "$pkgfile"

# name and email of uploader
name=$(git config user.name)
perl -s -i -0777 -pe 's/<<<NAME>>>/$to/' -- -to="$name" "$pkgfile"
email=$(git config user.email)
perl -s -i -0777 -pe 's/<<<EMAIL>>>/$to/' -- -to="$email" "$pkgfile"


# upload using ctan-o-mat
ctan-o-mat -s --config "$pkgfile"

# clean up by deleting modified config file
rm "$pkgfile"
