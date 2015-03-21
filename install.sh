#!/bin/bash

# This script installs Gregorio and GregorioTeX as cloned from GitHub and built
# using git-build.sh for a GNU system (like GNU/Linux), using default options.
#
# For now, it passes its argument to install-gtex.sh, defaulting to system.
#
# If you need something more complex, you probably know more than we do, so run
# the commands manually.

function die {
	echo "Failed to $1.  Did you forget to run as root?"
	exit 1
}

echo "Installing Gregorio"
make install || die "install Gregorio"
echo

echo "Installing GregorioTeX"
install-gtex.sh "${1:-system}" || die "install GregorioTeX"
echo

echo "Installation complete."

exit 0
