AM_CPPFLAGS = -I$(top_srcdir)/include -I$(top_srcdir)/lib
AM_CFLAGS = -L$(top_builddir)/lib

if ALL_STATIC
noinst_LTLIBRARIES=dump.la
else
pkglib_LTLIBRARIES=dump.la
endif
dump_la_SOURCES=dump.c dump.h
dump_la_LDFLAGS=-no-undefined -module -avoid-version
dump_la_LIBADD = $(LIBINTL) -lgregorio
