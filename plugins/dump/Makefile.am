AM_CPPFLAGS = -I$(top_srcdir)/include -I$(top_srcdir)/lib
AM_CFLAGS = $(GLIB_CFLAGS) -L$(top_builddir)/lib

pkglib_LTLIBRARIES=dump.la
dump_la_SOURCES=dump.c dump.h
dump_la_LDFLAGS=-no-undefined -module -avoid-version
dump_la_LIBADD = $(GLIB_LIBS) $(LIBINTL) -lgregorio
