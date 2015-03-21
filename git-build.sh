#!/bin/bash

# This script configures and builds Gregorio as cloned from GitHub for a GNU
# system (like GNU/Linux), using default options.
#
# For now, it passes all arguments to configure.
#
# If you need something more complex, you probably know more than we do, so run
# the commands manually.

function die {
	echo "Failed to $1."
	exit 1
}

CPUS=`nproc 2>/dev/null || echo 1`

echo "Creating build files using Autotools"
autoreconf -f -i || die "create build files"
echo

echo "Configuring using options: $@"
./configure "$@" || die "configure Gregorio"
echo

echo "Building"
make -j${CPUS} || die "build Gregorio"
echo

echo "Build complete.  Next, run ./git-install.sh to install."
echo
echo "Depending on installation directory, you probably need to run"
echo "./git-install.sh using sudo or as root."

exit 0
