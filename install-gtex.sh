#!/bin/bash

# This script installs the GregorioTeX portion of Gregorio.
#
# There are three ways to use this script:
#
# install-gtex.sh var:{tex-variable}
#
#   Installs GregorioTeX into the directory named by the given {tex-variable}.
#   If the PREFIX environment variable is set, it will be prepended.
#
#   Example: install-gtex.sh var:TEXMFLOCAL
#   - Installs GregorioTeX into the local TEXMF directory
#
#   Example: install-gtex.sh var:TEXMFHOME
#   - Installs GregorioTeX into the user's personal TEXMF directory
#
# install-gtex.sh dir:{directory}
#
#   Installs GregorioTeX into the {directory} directory.
#
#   Example: install-gtex.sh dir:/tmp/gtex
#   - Installs GregorioTeX into /tmp/gtex
#
# install-gtex.sh tds
#
#   Creates a TDS-ready archive named gregoriotex.tds.zip
#

TEXFILES=(tex/*.tex tex/gregorio*.sty tex/*.lua)
TTFFILES=(gregorio.ttf greciliae.ttf parmesan.ttf gresym.ttf greextra.ttf)
DOCFILES=(fonts/INSTALL fonts/FONTLOG)
FONTSRCFILES=(Makefile gregorio-base.sfd parmesan-base.sfd greciliae-base.sfd
              greextra.sfd gresym.sfd squarize.py convertsfdtottf.py)

NAME=${NAME:-gregoriotex}
FORMAT=${FORMAT:-luatex}
TEXHASH=${TEXHASH:-texhash}
KPSEWHICH=${KPSEWHICH:-kpsewhich}

TTFFILES=("${TTFFILES[@]/#/fonts/}")
FONTSRCFILES=("${FONTSRCFILES[@]/#/fonts/}")

case "$1" in
	"")
		;;
	tds)
		TDS_ZIP="${NAME}.tds.zip"
		TEXMFROOT=./tmp-texmf
		;;
	var:*)
		TEXMFROOT=`${KPSEWHICH} -var-value "${1#var:}"`
		if [ "$TEXMFROOT" = "" ]
		then
			echo "Invalid TeX variable: '${1#var:}'"
			echo
		else
			TEXMFROOT="${PREFIX}${TEXMFROOT}"
		fi
		;;
	dir:*)
		TEXMFROOT="${1#dir:}"
		;;
	*)
		echo "Invalid argument: '$1'"
		echo
		;;
esac

if [ "$TEXMFROOT" = "" ]
then
	echo "Usage: $0 var:{tex-variable}"
	echo "       $0 dir:{directory}"
	echo "       $0 tds"
	exit 1
fi

function die {
	echo 'Failed.'
	exit 1
}

function install_to {
	dir="$1"
	shift
	mkdir -p "$dir" || die
	cp "$@" "$dir" || die
}

echo "Installing in '${TEXMFROOT}'."
install_to "${TEXMFROOT}/tex/${FORMAT}/${NAME}" "${TEXFILES[@]}"
install_to "${TEXMFROOT}/fonts/truetype/public/${NAME}" "${TTFFILES[@]}"
install_to "${TEXMFROOT}/doc/${FORMAT}/${NAME}" "${DOCFILES[@]}"
install_to "${TEXMFROOT}/fonts/source/${NAME}" "${FONTSRCFILES[@]}"

if [ "$1" = 'tds' ]
then
	echo "Making TDS-ready archive ${TDS_ZIP}."
	rm -f ${TDS_ZIP}
	(cd ${TEXMFROOT} && zip -9 ../${TDS_ZIP} -q -r .) || die
	rm -r ${TEXMFROOT} || die
else
	${TEXHASH} || die
fi
