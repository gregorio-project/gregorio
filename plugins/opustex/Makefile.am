AM_CPPFLAGS=-I$(top_srcdir)/include -I$(top_srcdir)/lib
AM_CFLAGS = $(GLIB_CFLAGS) -L$(top_builddir)/lib

pkglib_LTLIBRARIES=opustex.la
opustex_la_SOURCES=opustex-write.c opustex.h
opustex_la_LDFLAGS=-no-undefined -module -avoid-version
opustex_la_LIBADD = $(GLIB_LIBS) $(LIBINTL) -lgregorio

