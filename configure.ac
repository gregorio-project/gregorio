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

AC_INIT([gregorio],[3.0.0-beta],[gregorio-devel@gna.org])
AC_PREREQ(2.59)
AC_CONFIG_SRCDIR([src/gregorio-utils.c])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])

AM_INIT_AUTOMAKE([foreign])

AC_PROG_CC
AC_PROG_CC_STDC
AC_PROG_CPP
AM_PROG_LEX
AC_PROG_YACC
AC_PROG_LIBTOOL
AC_CHECK_TOOL([RC], [windres], [no])
AM_CONDITIONAL([HAVE_RC], [test x$RC != xno])

AX_CHECK_COMPILE_FLAG([-fstack-protector-strong], [CFLAGS+=" -fstack-protector-strong"])
AX_CHECK_COMPILE_FLAG([-fPIE], [CFLAGS+=" -fPIE"])
AX_CHECK_COMPILE_FLAG([-Wformat], [CFLAGS+=" -Wformat"])
AX_CHECK_COMPILE_FLAG([-Werror=format-security], [CFLAGS+=" -Werror=format-security"])
CPPFLAGS+=" -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 "
AX_CHECK_LINK_FLAG([-Wl,-z,relro], [LDFLAGS+=" -Wl,-z,relro"])
AX_CHECK_LINK_FLAG([-Wl,-z,now], [LDFLAGS+=" -Wl,-z,now"])
AX_CHECK_LINK_FLAG([-fPIE], [LDFLAGS+=" -fPIE"])
AX_CHECK_LINK_FLAG([-pie], [LDFLAGS+=" -pie"])

AC_HEADER_STDC

# linux has integer types in stdint.h, solaris, vms in inttypes.h
AC_CHECK_HEADERS([stdint.h])

AC_ARG_ENABLE(static-ltdl, 
    [  --enable-static-ltdl    statical linking with libltdl (useful for MacOSX).], 
    [LIBTOOL_LIB=$LIBTOOL_LIB_STATIC], 
    [LIBTOOL_LIB=-lltdl]
)

AC_SUBST(LIBTOOL_LIB)

AC_DEFINE([_GNU_SOURCE], [1], [Always define this.])

AM_CONFIG_HEADER([src/config.h])
AC_CONFIG_FILES([
    Makefile
    src/Makefile
    src/dump/Makefile
    src/gabc/Makefile
    src/gregoriotex/Makefile
    examples/Makefile
    contrib/Makefile
    doc/Makefile
    tex/Makefile
    fonts/Makefile
])
AC_OUTPUT
