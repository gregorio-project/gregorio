AM_CPPFLAGS=-I$(top_srcdir)/include -I$(top_srcdir)/lib
AM_CFLAGS = -L$(top_builddir)/lib

if ALL_STATIC
noinst_LTLIBRARIES=opustex.la
else
pkglib_LTLIBRARIES=opustex.la
endif
opustex_la_SOURCES=opustex-write.c opustex.h
opustex_la_LDFLAGS=-no-undefined -module -avoid-version
opustex_la_LIBADD = $(LIBINTL) -lgregorio

