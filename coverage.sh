#!/bin/bash

# Copyright (C) 2016 The Gregorio Project (see CONTRIBUTORS.md)
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
# This script helps with code coverage testing.  It's meant to be run
# from the directory where it resides.

case "$1" in
report)
    eval `grep '^CC=' config.log`
    case "$CC" in
    gcc*)
        extra_args=''
        ;;
    clang*)
        echo "creating __gcovtool.sh for $CC"
        cat <<'EOT' > __gcovtool.sh
#!/bin/bash
exec llvm-cov gcov "$@"
EOT
        chmod +x __gcovtool.sh
        extra_args="--gcov-tool ${PWD}/__gcovtool.sh"
        ;;
    *)
        echo "compiler '$CC' not supported"
        exit 1
        ;;
    esac

    rm -rv coverage.info coverage
    echo "generating report"
    lcov $extra_args --directory . --capture --output-file coverage.info &&
        genhtml coverage.info -o coverage

    if test -f __gcovtool.sh
    then
        rm -v __gcovtool.sh
    fi
    ;;
clean)
    echo "deleting coverage files"
    rm -rv gcovtool.sh coverage coverage.info
    find . -name '*.gcno' -exec rm -v {} +
    find . -name '*.gcda' -exec rm -v {} +
    ;;
'')
    echo "Usage $0 report|clean"
    exit 1
    ;;
*)
    echo "command '$1' not recognized"
    exit 1
    ;;
esac

exit 0
