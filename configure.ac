dnl Gregorio
dnl Copyright (C) 2006 Elie Roux
dnl
dnl This program is free software; you can redistribute it and/or
dnl modify it under the terms of the GNU General Public License
dnl as published by the Free Software Foundation; either version 2
dnl of the License, or (at your option) any later version.
dnl 
dnl This program is distributed in the hope that it will be useful,
dnl but WITHOUT ANY WARRANTY; without even the implied warranty of
dnl MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
dnl GNU General Public License for more details.
dnl 
dnl You should have received a copy of the GNU General Public License
dnl along with this program; if not, write to the Free Software
dnl Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

AC_INIT([gregorio],[1.1-svn],[gregorio-devel@gna.org])
AC_PREREQ(2.53)
AC_CONFIG_SRCDIR([src/gregorio-utils.c])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])

AM_INIT_AUTOMAKE([foreign])
AM_GNU_GETTEXT([external])
AM_GNU_GETTEXT_VERSION([0.15])

# libgregorio versioning
LIBGREGORIO_CURRENT=0
LIBGREGORIO_REVISION=0
LIBGREGORIO_AGE=0
AC_SUBST(LIBGREGORIO_CURRENT)
AC_SUBST(LIBGREGORIO_REVISION)
AC_SUBST(LIBGREGORIO_AGE)

AC_PROG_CC
AC_PROG_CPP
AM_PROG_LEX
AC_PROG_YACC
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

## a dirty patch for cygwin, who needs the -lintl explicit option, that doesn't work under linux
AC_CHECK_PROGS(UNAME, uname, :)
if test "$UNAME" = :; then
  AC_MSG_ERROR([Could not find uname.])
else
  HOST_OS=`$UNAME -o`
  if test "$HOST_OS" = "Cygwin"; then
    LIBINTL=-lintl
    LEXLIB=''
    AC_SUBST(LIBINTL)
  fi
  ## a patch for statically linking libltdl under mac
  HOST_OS=`$UNAME -s`
  if test "$HOST_OS" = "Darwin"; then
    LIBTOOL_LIB_STATIC=/usr/lib/libltdl.a
  else
    LIBTOOL_LIB_STATIC="-lltdl -static"
  fi
  AC_SUBST(LIBTOOL_LIB_STATIC)
fi

AC_HEADER_STDC
AC_CHECK_PROGS(XML2_CONFIG, xml2-config, :)
if test "$XML2_CONFIG" = :; then
  AC_MSG_ERROR([Could not find xml2-config.])
else
  AC_DEFINE(HAVE_LIBXML2, 1, [Define if you have libxml2])
  # xml2-config in some versions erroneously includes -I/include
  # in the --cflags output.
  XML_CFLAGS="$CFLAGS `$XML2_CONFIG --cflags | sed 's|-I/include||g'`"
  AC_SUBST(XML_CFLAGS)
  XML_LIBS="$LIBS `$XML2_CONFIG --libs | sed 's|-L/usr/lib||g'`"
  AC_SUBST(XML_LIBS)
fi

AC_ARG_ENABLE(glib-utf8, 
    [  --enable-glib-utf8 link with glib for the character system.\
    This option is optional under Linux and MacOSX, but necessary under Windows.], 
    [AC_DEFINE([GREGORIO_GLIB], [1], [Glib or OS-dependant wchar_t character system.])
    AM_PATH_GLIB_2_0( 2.0.0, [], [AC_MSG_FAILURE([Glib not found])])
    ], [AC_DEFINE([GREGORIO_GLIB], [0], [Glib or OS-dependant wchar_t character system.])
    GLIB_LIBS=
    AC_SUBST(GLIB_LIBS)
    GLIB_CFLAGS=
    AC_SUBST(GLIB_CFLAGS)
    ]
)

AC_ARG_ENABLE(static-ltdl, 
    [  --enable-static-ltdl for statical linking with libltdl (useful for MacOSX packages).], 
    [LIBTOOL_LIB=$LIBTOOL_LIB_STATIC], 
    [LIBTOOL_LIB=-lltdl]
)
    
AC_SUBST(LIBTOOL_LIB)

AC_DEFINE([_GNU_SOURCE], [1], [Always define this.])

AM_CONFIG_HEADER([include/config.h])
AC_CONFIG_FILES([
    Makefile
    src/Makefile
    plugins/Makefile
    plugins/dump/Makefile
    plugins/gabc/Makefile
    plugins/xml/Makefile
    plugins/gregoriotex/Makefile
    plugins/opustex/Makefile
    lib/Makefile
    lib/gregorio.pc
    include/Makefile
    include/gregorio/Makefile
    examples/Makefile
    contrib/Makefile
    tex/Makefile
    po/Makefile.in
])
AC_OUTPUT
