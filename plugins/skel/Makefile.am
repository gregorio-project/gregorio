AM_CPPFLAGS=-I$(top_srcdir)/include -I$(top_srcdir)/lib
AM_CFLAGS= -L$(top_builddir)/lib

if ALL_STATIC
noinst_LTLIBRARIES=skel.la
else
pkglib_LTLIBRARIES=skel.la
endif
skel_la_SOURCES=skel.c
skel_la_LDFLAGS=-no-undefined -module -avoid-version
skel_la_LIBADD= $(LIBINTL) -lgregorio
