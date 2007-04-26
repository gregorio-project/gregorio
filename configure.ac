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

AC_INIT([gregorio], [0.3], [gregorio-devel@gna.org])
AC_PREREQ([2.60])
AC_CONFIG_SRCDIR([src/gregorio-utils.c])
AC_CONFIG_AUX_DIR([build-aux])

AM_INIT_AUTOMAKE([-Wall -Werror foreign])

AC_PROG_CC
AC_PROG_CPP
AC_PROG_LEX
AC_PROG_YACC

AC_HEADER_STDC
AC_CHECK_PROGS(XML2_CONFIG, xml2-config, :)
if test "$XML2_CONFIG" = :; then
  AC_MSG_ERROR([Could not find xml2-config.])
else
  AC_DEFINE(HAVE_LIBXML2, 1, [Define if you have libxml2])
  # xml2-config in some versions erroneously includes -I/include
  # in the --cflags output.
  CFLAGS="$CFLAGS `$XML2_CONFIG --cflags | sed 's|-I/include||g'`"
  LIBS="$LIBS `$XML2_CONFIG --libs | sed 's|-L/usr/lib||g'`"
fi

AC_CONFIG_HEADERS([include/config.h])
AC_CONFIG_FILES([
    Makefile
    src/Makefile
    include/Makefile
    examples/Makefile
    fonts/Makefile
    tex/Makefile
])
AC_OUTPUT
